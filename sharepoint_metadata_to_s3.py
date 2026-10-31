# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — Métadonnées SharePoint → S3 (oneshot)
# MAGIC
# MAGIC Récupère les colonnes de métadonnées de la bibliothèque `Documents` (AssessmentID,
# MAGIC PlantId, Element, etc.) et écrit **un fichier JSON par document** dans `metadata/`,
# MAGIC à côté de `sharepoint/` sur le même bucket.
# MAGIC
# MAGIC Le chemin du JSON reproduit celui du fichier associé
# MAGIC (`metadata/<même chemin que dans sharepoint/>.json`), pour pouvoir les recoller
# MAGIC facilement. S'appuie sur le même Volume externe que [sharepoint_to_s3.py](sharepoint_to_s3.py)
# MAGIC (`leanix_dev.default.opex-s3`, monté sur `s3://demo-document-bucket/`).

# COMMAND ----------

# MAGIC %pip install --quiet msal python-dotenv

# COMMAND ----------

import json
import os
import re
from urllib.parse import unquote

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
BUCKET_ROOT_DIR = "/Volumes/leanix_dev/default/opex-s3"
METADATA_DIR    = f"{BUCKET_ROOT_DIR}/metadata"

# Test : ne traiter que les N premiers items trouvés. Mettre à None pour tout copier.
MAX_ITEMS = None

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Auth Microsoft Graph (+ wrapper refresh token)

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
# MAGIC ## 2. Site SharePoint

# COMMAND ----------

r = graph_get(f"{GRAPH_ROOT}/sites/{SHAREPOINT_HOST}:{SHAREPOINT_SITE_PATH}", timeout=30)
SITE_ID = r.json()["id"]
print(f"site_id = {SITE_ID}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2bis. Racine du drive (pour recalculer rel_path exactement comme sharepoint_to_s3.py)
# MAGIC
# MAGIC Le nom affiché de la bibliothèque dans les URLs (`Documents%20partages`) n'est pas
# MAGIC forcément `Documents` — on ne peut pas juste découper sur `/Documents/`. On résout
# MAGIC le même drive que sharepoint_to_s3.py et on prend son `webUrl` comme racine.

# COMMAND ----------

r = graph_get(f"{GRAPH_ROOT}/sites/{SITE_ID}/drives", timeout=30)
drives = r.json().get("value", [])
DRIVE_ID = None
for d in drives:
    if d.get("name") in {LIST_DOCUMENTS, "Documents", "Documents partagés", "Shared Documents"}:
        DRIVE_ID = d["id"]
        break
if not DRIVE_ID and drives:
    DRIVE_ID = drives[0]["id"]
if not DRIVE_ID:
    raise RuntimeError("aucun drive trouvé")

r = graph_get(f"{GRAPH_ROOT}/drives/{DRIVE_ID}/root", timeout=30)
DRIVE_ROOT_WEB_URL = unquote(r.json()["webUrl"]).rstrip("/")
print(f"drive_id = {DRIVE_ID}")
print(f"drive root webUrl = {DRIVE_ROOT_WEB_URL}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Items de la liste `Documents` (avec colonnes/metadata) → JSON par doc

# COMMAND ----------

def sanitize(path: str) -> str:
    return re.sub(r"[^\w\-./ ()]+", "_", path)


def rel_path_from_item(item: dict) -> str:
    """Reconstruit le même chemin relatif que celui utilisé pour les fichiers dans
    sharepoint_to_s3.py : webUrl de l'item, moins le webUrl racine du drive."""
    web_url = unquote(item.get("webUrl", ""))
    prefix = DRIVE_ROOT_WEB_URL + "/"
    if web_url.startswith(prefix):
        return web_url[len(prefix):]
    fields = item.get("fields", {}) or {}
    return fields.get("FileLeafRef") or f"unknown_{item.get('id')}"


def list_items(list_name: str):
    url = f"{GRAPH_ROOT}/sites/{SITE_ID}/lists/{list_name}/items?expand=fields&$top=200"
    while url:
        r = graph_get(url, timeout=60)
        payload = r.json()
        for it in payload.get("value", []):
            yield it
        url = payload.get("@odata.nextLink")


os.makedirs(METADATA_DIR, exist_ok=True)

written, skipped_folders, failed = [], 0, []
for item in list_items(LIST_DOCUMENTS):
    if MAX_ITEMS is not None and len(written) >= MAX_ITEMS:
        print(f"MAX_ITEMS={MAX_ITEMS} atteint, arrêt (mode test)")
        break

    fields = item.get("fields", {}) or {}
    if fields.get("ContentType") == "Folder":  # dossier, pas un document
        skipped_folders += 1
        continue

    item_id = item.get("id", "")
    rel = rel_path_from_item(item)
    meta_path = os.path.join(METADATA_DIR, sanitize(rel) + ".json")

    try:
        metadata = {
            "sharepoint_item_id": item_id,
            "sharepoint_web_url": item.get("webUrl"),
            "created_at": item.get("createdDateTime") or fields.get("Created"),
            "modified_at": item.get("lastModifiedDateTime") or fields.get("Modified"),
            "rel_path": rel,
            "s3_document_key": f"sharepoint/{sanitize(rel)}",
            # Colonnes métier identifiées sur la liste Documents
            "title": fields.get("Title"),
            "description": fields.get("_ExtendedDescription"),
            "security_classification": fields.get("Security_x0020_Classification"),
            "assessment_id": fields.get("AssessmentID"),
            "old_assessment_id": fields.get("OldAssessmentID"),
            "question_id": fields.get("QuestionID"),
            "old_question_id": fields.get("OldQuestionID"),
            "question_number": fields.get("QuestionNumber"),
            "plant_id": fields.get("PlantId"),
            "assessment_type": fields.get("AssessmentType"),
            "element": fields.get("Element"),
            "acc": fields.get("ACC"),
            "peer_score": fields.get("DocumentScore"),
            "viewers": fields.get("Viewers"),
            "content_type": fields.get("ContentType"),
            # Tout le reste, brut, pour ne rien perdre
            "raw_fields": fields,
        }
        os.makedirs(os.path.dirname(meta_path), exist_ok=True)
        with open(meta_path, "w", encoding="utf-8") as f:
            json.dump(metadata, f, ensure_ascii=False, indent=2)
        written.append(rel)
        print(f"  ✓ {rel} → {meta_path}")
    except Exception as e:
        failed.append({"rel_path": rel, "error": str(e)})
        print(f"  ✗ {rel}: {e}")

print(f"\n{len(written)} métadonnées écrites, {skipped_folders} dossiers ignorés, {len(failed)} échecs")
if failed:
    print(failed)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Récap

# COMMAND ----------

summary = {
    "site_id": SITE_ID,
    "metadata_target": "s3://demo-document-bucket/metadata/",
    "volume_target": METADATA_DIR,
    "files_written": len(written),
    "folders_skipped": skipped_folders,
    "files_failed": len(failed),
}
print(summary)
