# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — Relink des métadonnées SharePoint dans la nouvelle DB
# MAGIC
# MAGIC Pour chaque JSON de métadonnées produit par [sharepoint_metadata_to_s3.py](sharepoint_metadata_to_s3.py)
# MAGIC (dans `metadata/` sur le bucket), crée le lien dans la nouvelle DB :
# MAGIC
# MAGIC 1. retrouve le document dans `documents` via `storage_path = s3_document_key`
# MAGIC    (fallback : `url = sharepoint_web_url`) — les documents sont **déjà migrés**,
# MAGIC    on n'en crée pas, on skip ceux introuvables ;
# MAGIC 2. résout l'assessment : le `assessment_id` SharePoint (ex. `"409"`) est devenu
# MAGIC    `assessments.old_assessment_id` dans la nouvelle DB → on récupère l'`id` uuid ;
# MAGIC 3. insère une ligne `document_links (document_id, assessment_id, answer_id NULL)`,
# MAGIC    en skippant celles qui existent déjà (idempotent).
# MAGIC
# MAGIC `DRY_RUN = True` par défaut : tout est lu, rien n'est écrit (rollback final).

# COMMAND ----------

# MAGIC %pip install --quiet psycopg2-binary python-dotenv

# COMMAND ----------

import json
import os
import uuid

import psycopg2
from dotenv import load_dotenv

load_dotenv()  # no-op sur Databricks (pas de .env), utile en local

# COMMAND ----------

# MAGIC %md
# MAGIC ## Config
# MAGIC
# MAGIC Mêmes variables DB que [test_infra.py](test_infra.py). Creds via `.env` en local,
# MAGIC ou variables d'env / secret scope sur Databricks.

# COMMAND ----------

def env(key: str) -> str:
    v = os.environ.get(key, "")
    if not v:
        raise RuntimeError(f"env var manquante: {key}")
    return v

# RDS Aurora (nouvelle DB)
DB_HOST     = env("DB_HOST")
DB_PORT     = int(os.environ.get("DB_PORT", "5432"))
DB_NAME     = env("DB_NAME")
DB_USER     = env("DB_USER")
DB_PASSWORD = env("DB_PASSWORD")

# Métadonnées : volume externe monté sur le bucket S3 (cf. sharepoint_metadata_to_s3.py).
# Surchargeable en local via METADATA_DIR.
METADATA_DIR = os.environ.get(
    "METADATA_DIR", "/Volumes/leanix_dev/default/opex-s3/metadata"
)

# True = lecture seule (rollback) ; False = écrit réellement
DRY_RUN = True

# Test : ne traiter que les N premiers JSON. Mettre à None pour tout traiter.
MAX_ITEMS = None

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Connexion DB + préchargement du mapping `old_assessment_id → id`

# COMMAND ----------

conn = psycopg2.connect(
    host=DB_HOST, port=DB_PORT, dbname=DB_NAME,
    user=DB_USER, password=DB_PASSWORD, connect_timeout=10,
)
conn.autocommit = False

with conn.cursor() as cur:
    cur.execute("""
        SELECT id, old_assessment_id
        FROM public.assessments
        WHERE old_assessment_id IS NOT NULL
    """)
    rows = cur.fetchall()

ASSESSMENT_BY_OLD_ID = {}
for assessment_id, old_id in rows:
    key = str(old_id).strip()
    if key in ASSESSMENT_BY_OLD_ID and ASSESSMENT_BY_OLD_ID[key] != assessment_id:
        print(f"  ⚠ old_assessment_id dupliqué '{key}' — première valeur conservée")
        continue
    ASSESSMENT_BY_OLD_ID[key] = assessment_id

print(f"{len(ASSESSMENT_BY_OLD_ID)} assessments avec old_assessment_id chargés")

with conn.cursor() as cur:
    cur.execute("SELECT count(*) FROM public.documents")
    n_docs = cur.fetchone()[0]
    cur.execute("SELECT count(*) FROM public.document_links")
    n_links = cur.fetchone()[0]
print(f"{n_docs} documents, {n_links} document_links déjà en base")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Helpers de résolution

# COMMAND ----------

def find_document_id(cur, meta: dict):
    """Retrouve le document migré. Match principal sur storage_path (clé S3),
    fallback sur l'URL SharePoint. Renvoie (id, méthode) ou (None, None)."""
    s3_key = meta.get("s3_document_key")
    if s3_key:
        cur.execute(
            "SELECT id FROM public.documents WHERE storage_path = %s", (s3_key,)
        )
        row = cur.fetchone()
        if row:
            return row[0], "storage_path"
    web_url = meta.get("sharepoint_web_url")
    if web_url:
        cur.execute(
            "SELECT id FROM public.documents WHERE url = %s", (web_url,)
        )
        row = cur.fetchone()
        if row:
            return row[0], "url"
    return None, None


def resolve_assessment_ids(meta: dict):
    """Le assessment_id SharePoint (parfois multi-valeurs '409, 410') → ids uuid
    de la nouvelle DB via assessments.old_assessment_id."""
    raw = meta.get("assessment_id")
    if raw is None or str(raw).strip() == "":
        return [], ["(vide)"]
    found, missing = [], []
    for part in str(raw).split(","):
        old_id = part.strip()
        if not old_id:
            continue
        assessment_id = ASSESSMENT_BY_OLD_ID.get(old_id)
        if assessment_id:
            found.append(assessment_id)
        else:
            missing.append(old_id)
    return found, missing


def link_exists(cur, document_id, assessment_id) -> bool:
    cur.execute(
        """
        SELECT 1 FROM public.document_links
        WHERE document_id = %s AND assessment_id = %s AND answer_id IS NULL
        """,
        (document_id, assessment_id),
    )
    return cur.fetchone() is not None

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Parcours des JSON de métadonnées → `document_links`

# COMMAND ----------

stats = {
    "json_lus": 0,
    "liens_crees": 0,
    "liens_existants": 0,
    "doc_introuvable": 0,
    "assessment_introuvable": 0,
    "sans_assessment_id": 0,
    "erreurs": 0,
}
report = {
    "doc_introuvable": [],        # rel_path des documents non matchés
    "assessment_introuvable": [], # (rel_path, old_assessment_id)
    "erreurs": [],                # (rel_path, message)
}

processed = 0
for dirpath, _, filenames in os.walk(METADATA_DIR):
    for fn in sorted(filenames):
        if not fn.endswith(".json"):
            continue
        if MAX_ITEMS is not None and processed >= MAX_ITEMS:
            print(f"MAX_ITEMS={MAX_ITEMS} atteint, arrêt (mode test)")
            break

        path = os.path.join(dirpath, fn)
        try:
            with open(path, encoding="utf-8") as f:
                meta = json.load(f)
        except Exception as e:
            stats["erreurs"] += 1
            report["erreurs"].append({"file": fn, "error": f"JSON illisible: {e}"})
            continue

        processed += 1
        stats["json_lus"] += 1
        rel = meta.get("rel_path") or fn

        try:
            with conn.cursor() as cur:
                document_id, how = find_document_id(cur, meta)
                if not document_id:
                    stats["doc_introuvable"] += 1
                    report["doc_introuvable"].append(rel)
                    print(f"  ✗ doc introuvable : {rel}")
                    continue

                assessment_ids, missing = resolve_assessment_ids(meta)
                if missing == ["(vide)"]:
                    stats["sans_assessment_id"] += 1
                for old_id in missing:
                    if old_id == "(vide)":
                        continue
                    stats["assessment_introuvable"] += 1
                    report["assessment_introuvable"].append(
                        {"rel_path": rel, "old_assessment_id": old_id}
                    )
                    print(f"  ✗ assessment introuvable (old_id={old_id}) : {rel}")

                for assessment_id in assessment_ids:
                    if link_exists(cur, document_id, assessment_id):
                        stats["liens_existants"] += 1
                        continue
                    cur.execute(
                        """
                        INSERT INTO public.document_links
                            (id, document_id, assessment_id, answer_id)
                        VALUES (%s, %s, %s, NULL)
                        """,
                        (str(uuid.uuid4()), document_id, assessment_id),
                    )
                    stats["liens_crees"] += 1
                    print(f"  ✓ {rel} → assessment {assessment_id} (match {how})")
        except Exception as e:
            stats["erreurs"] += 1
            report["erreurs"].append({"rel_path": rel, "error": str(e)})
            print(f"  ✗ {rel}: {e}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Commit / rollback + récap

# COMMAND ----------

if DRY_RUN:
    conn.rollback()
    print("DRY_RUN=True → rollback, rien n'a été écrit.")
else:
    conn.commit()
    print("commit OK")
conn.close()

report_path = "relink_report.json"
with open(report_path, "w", encoding="utf-8") as f:
    json.dump({"dry_run": DRY_RUN, "stats": stats, **report}, f,
              ensure_ascii=False, indent=2, default=str)

print(json.dumps(stats, indent=2, ensure_ascii=False))
print(f"rapport détaillé : {os.path.abspath(report_path)}")
