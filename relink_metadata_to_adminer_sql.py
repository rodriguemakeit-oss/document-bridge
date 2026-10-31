# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — Génération SQL de relink pour Adminer
# MAGIC
# MAGIC Pour chaque JSON de métadonnées produit par [sharepoint_metadata_to_s3.py](sharepoint_metadata_to_s3.py)
# MAGIC (dans `metadata/` sur le bucket), génère un script SQL à exécuter dans Adminer :
# MAGIC
# MAGIC 1. retrouve le document dans `documents` via `storage_path = s3_document_key`
# MAGIC    (fallback : `url = sharepoint_web_url`) ;
# MAGIC 2. résout l'assessment via `assessments.old_assessment_id` ;
# MAGIC 3. insère une ligne `document_links (document_id, assessment_id, answer_id NULL)`
# MAGIC    uniquement si elle n'existe pas déjà.
# MAGIC
# MAGIC Le script Python ne se connecte pas à la DB : il produit un fichier `.sql`
# MAGIC et un rapport JSON, puis le SQL est exécuté manuellement dans Adminer.

# COMMAND ----------

# MAGIC %pip install --quiet python-dotenv

# COMMAND ----------

import json
import os
import re
from dotenv import load_dotenv

load_dotenv()  # no-op sur Databricks (pas de .env), utile en local

# COMMAND ----------

# MAGIC %md
# MAGIC ## Config
# MAGIC
# MAGIC Aucune connexion DB ici. On lit uniquement les JSON de métadonnées et on génère
# MAGIC un `.sql` exécutable dans Adminer.

# COMMAND ----------

# Métadonnées : volume externe monté sur le bucket S3 (cf. sharepoint_metadata_to_s3.py).
# Surchargeable en local via METADATA_DIR.
METADATA_DIR = os.environ.get(
    "METADATA_DIR", "/Volumes/leanix_dev/default/opex-s3/metadata"
)

# Volume de sortie pour les artefacts générés.
OUTPUT_DIR = os.environ.get(
    "OUTPUT_DIR", "/Volumes/opex_gold/default/opex_dev_s3"
)

# Fichier SQL produit pour exécution manuelle dans Adminer.
SQL_OUTPUT_PATH = os.environ.get(
    "SQL_OUTPUT_PATH", os.path.join(OUTPUT_DIR, "relink_document_links.sql")
)

# Rapport JSON produit à côté du SQL.
REPORT_OUTPUT_PATH = os.environ.get(
    "REPORT_OUTPUT_PATH", os.path.join(OUTPUT_DIR, "relink_adminer_report.json")
)

# Test : ne traiter que les N premiers JSON. Mettre à None pour tout traiter.
MAX_ITEMS = None

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Helpers

# COMMAND ----------

def sql_literal(value):
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def sanitize_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("_") or "item"


def split_assessment_ids(meta: dict):
    raw = meta.get("assessment_id")
    if raw is None or str(raw).strip() == "":
        return [], True
    values = []
    for part in str(raw).split(","):
        old_id = part.strip()
        if old_id:
            values.append(old_id)
    return values, False


def build_insert_sql(meta: dict, old_assessment_id: str, block_index: int):
    rel_path = meta.get("rel_path") or "(sans rel_path)"
    s3_key = meta.get("s3_document_key")
    web_url = meta.get("sharepoint_web_url")
    if not s3_key and not web_url:
        raise ValueError("métadonnée sans s3_document_key ni sharepoint_web_url")

    doc_match_predicates = []
    if s3_key:
        doc_match_predicates.append(f"doc.storage_path = {sql_literal(s3_key)}")
    if web_url:
        doc_match_predicates.append(f"doc.url = {sql_literal(web_url)}")

    doc_match_sql = " OR ".join(doc_match_predicates)
    comment_slug = sanitize_name(rel_path)[:80]

    return f"""-- relink:{block_index}:{comment_slug}
-- rel_path: {rel_path}
-- old_assessment_id: {old_assessment_id}
INSERT INTO public.document_links (id, document_id, assessment_id, answer_id)
SELECT gen_random_uuid(), doc.id, ass.id, NULL
FROM public.documents AS doc
JOIN public.assessments AS ass
  ON ass.old_assessment_id = {sql_literal(old_assessment_id)}
WHERE ({doc_match_sql})
  AND NOT EXISTS (
      SELECT 1
      FROM public.document_links AS dl
      WHERE dl.document_id = doc.id
        AND dl.assessment_id = ass.id
        AND dl.answer_id IS NULL
  );
"""


def count_json_files(root_dir: str) -> int:
        count = 0
        for _, _, filenames in os.walk(root_dir):
                count += sum(1 for fn in filenames if fn.endswith(".json"))
        return count

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Parcours des JSON de métadonnées → génération du SQL

# COMMAND ----------

stats = {
    "json_lus": 0,
    "instructions_sql": 0,
    "json_sans_cle_document": 0,
    "sans_assessment_id": 0,
    "erreurs": 0,
}
report = {
    "metadata_dir": METADATA_DIR,
    "json_sans_cle_document": [],
    "sans_assessment_id": [],
    "erreurs": [],
}

sql_blocks = [
    "-- SQL généré automatiquement pour relier les métadonnées SharePoint aux assessments.",
    "-- Exécuter dans Adminer sur la base cible.",
    "BEGIN;",
]

print(f"METADATA_DIR = {METADATA_DIR}")
print(f"SQL_OUTPUT_PATH = {SQL_OUTPUT_PATH}")

if not os.path.isdir(METADATA_DIR):
    raise RuntimeError(
        f"METADATA_DIR introuvable: {METADATA_DIR}. "
        "Définis la variable d'environnement METADATA_DIR vers le dossier qui contient les JSON."
    )

json_files_count = count_json_files(METADATA_DIR)
if json_files_count == 0:
    raise RuntimeError(
        f"Aucun fichier .json trouvé dans METADATA_DIR: {METADATA_DIR}. "
        "Vérifie le volume source ou surcharge METADATA_DIR."
    )

print(f"{json_files_count} fichier(s) JSON détecté(s) dans {METADATA_DIR}")

processed = 0
block_index = 0
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
            if not meta.get("s3_document_key") and not meta.get("sharepoint_web_url"):
                stats["json_sans_cle_document"] += 1
                report["json_sans_cle_document"].append(rel)
                print(f"  ✗ aucune clé document exploitable : {rel}")
                continue

            old_assessment_ids, is_empty = split_assessment_ids(meta)
            if is_empty:
                stats["sans_assessment_id"] += 1
                report["sans_assessment_id"].append(rel)
                print(f"  ✗ assessment_id vide : {rel}")
                continue

            for old_assessment_id in old_assessment_ids:
                block_index += 1
                sql_blocks.append(build_insert_sql(meta, old_assessment_id, block_index))
                stats["instructions_sql"] += 1
                print(f"  ✓ SQL généré : {rel} → old_assessment_id={old_assessment_id}")
        except Exception as e:
            stats["erreurs"] += 1
            report["erreurs"].append({"rel_path": rel, "error": str(e)})
            print(f"  ✗ {rel}: {e}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Écriture des artefacts + récap

# COMMAND ----------

sql_blocks.append("COMMIT;")

os.makedirs(os.path.dirname(SQL_OUTPUT_PATH), exist_ok=True)

with open(SQL_OUTPUT_PATH, "w", encoding="utf-8") as f:
    f.write("\n\n".join(sql_blocks) + "\n")

with open(REPORT_OUTPUT_PATH, "w", encoding="utf-8") as f:
    json.dump({
        "sql_output_path": os.path.abspath(SQL_OUTPUT_PATH),
        "stats": stats,
        **report,
    }, f, ensure_ascii=False, indent=2, default=str)

print(json.dumps(stats, indent=2, ensure_ascii=False))
print(f"script SQL : {os.path.abspath(SQL_OUTPUT_PATH)}")
print(f"rapport détaillé : {os.path.abspath(REPORT_OUTPUT_PATH)}")