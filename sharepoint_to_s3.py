# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — SharePoint → S3 (oneshot)
# MAGIC
# MAGIC Récupère tous les fichiers de la bibliothèque `Documents` du site SharePoint OpEx
# MAGIC et les pousse tels quels vers S3. Pas de RDS.
# MAGIC
# MAGIC `leanix_dev.default.opex-s3` est un Volume Unity Catalog **externe**, monté
# MAGIC directement sur `s3://demo-document-bucket/`. Donc écrire dans
# MAGIC `/Volumes/leanix_dev/default/opex-s3/sharepoint/...` en Python natif (`open()`,
# MAGIC `write()`) équivaut à écrire directement sur S3 — pas de `dbutils.fs`, pas
# MAGIC d'étape de copie séparée.

# COMMAND ----------

# MAGIC %pip install --quiet msal python-dotenv

# COMMAND ----------

import os
import re

import msal
import requests
from dotenv import load_dotenv

load_dotenv()  # no-op sur Databricks (pas de .env), utile en local

# COMMAND ----------

# MAGIC %md
# MAGIC ## Config
# MAGIC
# MAGIC Creds via `.env` en local (voir `.env.example`), ou variables d'env / secret
# MAGIC scope sur Databricks. Rien en dur ici.

# COMMAND ----------

def env(key: str) -> str:
    v = os.environ.get(key, "")
    if not v:
        raise RuntimeError(f"env var manquante: {key}")
    return v

# Microsoft Graph (app registration Azure AD, tenant portfolio)
GRAPH_TENANT_ID     = env("GRAPH_TENANT_ID")
GRAPH_CLIENT_ID     = env("GRAPH_CLIENT_ID")
GRAPH_CLIENT_SECRET = env("GRAPH_CLIENT_SECRET")

# SharePoint
SHAREPOINT_HOST      = "example.sharepoint.com"
SHAREPOINT_SITE_PATH = "/sites/OperationalExcellenceGlobal"
LIST_DOCUMENTS       = "Documents"

# Volume externe monté directement sur le bucket S3 — écrire ici = écrire sur S3
VOLUME_DIR = "/Volumes/leanix_dev/default/opex-s3/sharepoint"

# Test : ne traiter que les N premiers fichiers trouvés. Mettre à None pour tout copier.
MAX_FILES = None

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Auth Microsoft Graph

# COMMAND ----------

def get_graph_token() -> str:
    app = msal.ConfidentialClientApplication(
        client_id=GRAPH_CLIENT_ID,
        client_credential=GRAPH_CLIENT_SECRET,
        authority=f"https://login.microsoftonline.com/{GRAPH_TENANT_ID}",
    )
    result = app.acquire_token_for_client(scopes=["https://graph.microsoft.com/.default"])
    if "access_token" not in result:
        raise RuntimeError(f"MSAL auth failed: {result}")
    return result["access_token"]


GRAPH_TOKEN = get_graph_token()
GRAPH_HEADERS = {"Authorization": f"Bearer {GRAPH_TOKEN}"}
GRAPH_ROOT = "https://graph.microsoft.com/v1.0"
print("token OK")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1bis. Wrapper avec refresh auto du token
# MAGIC
# MAGIC Le token Graph expire (~1h). Sur un run de plusieurs milliers de fichiers ça
# MAGIC arrive en cours de route : `graph_get` détecte le 401 et rafraîchit tout seul.

# COMMAND ----------

def graph_get(url, **kwargs):
    global GRAPH_TOKEN, GRAPH_HEADERS
    r = requests.get(url, headers=GRAPH_HEADERS, **kwargs)
    if r.status_code == 401:
        r.close()
        print("  (token Graph expiré, refresh...)")
        GRAPH_TOKEN = get_graph_token()
        GRAPH_HEADERS = {"Authorization": f"Bearer {GRAPH_TOKEN}"}
        r = requests.get(url, headers=GRAPH_HEADERS, **kwargs)
    r.raise_for_status()
    return r

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Site + drive SharePoint

# COMMAND ----------

r = graph_get(f"{GRAPH_ROOT}/sites/{SHAREPOINT_HOST}:{SHAREPOINT_SITE_PATH}", timeout=30)
SITE_ID = r.json()["id"]
print(f"site_id = {SITE_ID}")

r = graph_get(f"{GRAPH_ROOT}/sites/{SITE_ID}/drives", timeout=30)
drives = r.json().get("value", [])
DRIVE_ID = None
for d in drives:
    if d.get("name") in {LIST_DOCUMENTS, "Documents", "Documents partagés", "Shared Documents"}:
        DRIVE_ID = d["id"]
        print(f"drive '{d['name']}' → {DRIVE_ID}")
        break
if not DRIVE_ID and drives:
    DRIVE_ID = drives[0]["id"]
    print(f"fallback drive: {drives[0]['name']}")
if not DRIVE_ID:
    raise RuntimeError("aucun drive trouvé")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Parcours + copie SharePoint → S3
# MAGIC
# MAGIC Chaque fichier est écrit directement dans le Volume (= sur S3), en conservant
# MAGIC l'arborescence SharePoint comme structure de dossiers.

# COMMAND ----------

def walk_drive(drive_id, folder_id="root", rel_path=""):
    url = f"{GRAPH_ROOT}/drives/{drive_id}/items/{folder_id}/children?$top=1000"
    while url:
        r = graph_get(url, timeout=60)
        payload = r.json()
        for it in payload.get("value", []):
            child_rel = f"{rel_path}/{it['name']}" if rel_path else it["name"]
            if "folder" in it:
                yield from walk_drive(drive_id, it["id"], child_rel)
            elif "file" in it:
                yield child_rel, it
        url = payload.get("@odata.nextLink")


def sanitize(path: str) -> str:
    return re.sub(r"[^\w\-./ ()]+", "_", path)


copied, skipped, failed = [], [], []
for rel, item in walk_drive(DRIVE_ID):
    if MAX_FILES is not None and len(copied) + len(failed) >= MAX_FILES:
        print(f"MAX_FILES={MAX_FILES} atteint, arrêt (mode test)")
        break
    local_path = os.path.join(VOLUME_DIR, sanitize(rel))
    # Resume : si le fichier est déjà là avec la bonne taille, on ne le retélécharge pas
    if os.path.exists(local_path) and os.path.getsize(local_path) == item.get("size"):
        skipped.append(rel)
        continue
    dl_url = f"{GRAPH_ROOT}/drives/{DRIVE_ID}/items/{item['id']}/content"
    try:
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        with graph_get(dl_url, stream=True, timeout=120) as r:
            with open(local_path, "wb") as f:
                for chunk in r.iter_content(chunk_size=1 << 20):
                    if chunk:
                        f.write(chunk)
        copied.append({"rel_path": rel, "local_path": local_path, "size": item.get("size")})
        print(f"  ✓ {rel} ({item.get('size')} B) → {local_path}")
    except Exception as e:
        failed.append({"rel_path": rel, "error": str(e)})
        print(f"  ✗ {rel}: {e}")

print(f"\n{len(copied)} fichiers copiés, {len(skipped)} déjà présents (skip), {len(failed)} échecs")
if failed:
    print(failed)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Récap

# COMMAND ----------

summary = {
    "site_id": SITE_ID,
    "drive_id": DRIVE_ID,
    "s3_target": "s3://demo-document-bucket/sharepoint/",
    "volume_target": VOLUME_DIR,
    "files_copied": len(copied),
    "files_skipped": len(skipped),
    "files_failed": len(failed),
}
print(summary)
