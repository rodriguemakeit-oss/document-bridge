# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — test infra
# MAGIC
# MAGIC Dry-run pour valider les accès de bout en bout :
# MAGIC 1. lire les listes SharePoint `Documents` (metadata + fichiers) et `Library` (data)
# MAGIC 2. DL les fichiers dans un volume Databricks
# MAGIC 3. push sur S3 `demo-document-bucket`
# MAGIC 4. écrire une ligne de ping dans la RDS Aurora
# MAGIC
# MAGIC En attendant le catalog OpEx, on emprunte `labanalysis_dev`.

# COMMAND ----------

# MAGIC %pip install --quiet msal psycopg2-binary python-dotenv

# COMMAND ----------

import json
import os
import re
import uuid
from datetime import datetime, timezone

import boto3
import msal
import pandas as pd
import psycopg2
import requests
from dotenv import load_dotenv

load_dotenv()  # no-op sur Databricks (pas de .env), utile en local

# COMMAND ----------

# MAGIC %md
# MAGIC ## Config
# MAGIC
# MAGIC Creds via `.env` en local, ou variables d'env / `dbutils.secrets` sur Databricks.
# MAGIC Voir `.env.example`.

# COMMAND ----------

def env(key: str) -> str:
    v = os.environ.get(key, "")
    if not v:
        raise RuntimeError(f"env var manquante: {key}")
    return v

# Microsoft Graph
GRAPH_TENANT_ID     = env("GRAPH_TENANT_ID")
GRAPH_CLIENT_ID     = env("GRAPH_CLIENT_ID")
GRAPH_CLIENT_SECRET = env("GRAPH_CLIENT_SECRET")

# SharePoint (extrait de l'URL du site OpEx)
SHAREPOINT_HOST      = "example.sharepoint.com"
SHAREPOINT_SITE_PATH = "/sites/OperationalExcellenceGlobal"
LIST_DOCUMENTS = "Documents"
LIST_LIBRARY   = "Library"

# Staging Databricks
CATALOG    = "labanalysis_dev"
SCHEMA     = "default"
VOLUME     = "opex_test"
VOLUME_DIR = f"/Volumes/{CATALOG}/{SCHEMA}/{VOLUME}/downloads"

# S3 — auth via IAM role du compute
S3_BUCKET  = "demo-document-bucket"
S3_PREFIX  = "test-infra/"
AWS_REGION = "eu-west-1"

# RDS
RDS_HOST     = env("DB_HOST")
RDS_PORT     = int(os.environ.get("DB_PORT", "5432"))
RDS_DB       = env("DB_NAME")
RDS_USER     = env("DB_USER")
RDS_PASSWORD = env("DB_PASSWORD")

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
# MAGIC ## 2. Site SharePoint

# COMMAND ----------

r = requests.get(
    f"{GRAPH_ROOT}/sites/{SHAREPOINT_HOST}:{SHAREPOINT_SITE_PATH}",
    headers=GRAPH_HEADERS, timeout=30,
)
r.raise_for_status()
SITE_ID = r.json()["id"]
print(f"site_id = {SITE_ID}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Listes SharePoint → DataFrames

# COMMAND ----------

def fetch_list_items(list_name: str) -> pd.DataFrame:
    url = f"{GRAPH_ROOT}/sites/{SITE_ID}/lists/{list_name}/items?expand=fields&$top=1000"
    rows = []
    while url:
        r = requests.get(url, headers=GRAPH_HEADERS, timeout=60)
        r.raise_for_status()
        payload = r.json()
        for item in payload.get("value", []):
            fields = item.get("fields", {}) or {}
            fields["_item_id"] = item.get("id")
            fields["_created_at"] = item.get("createdDateTime")
            fields["_modified_at"] = item.get("lastModifiedDateTime")
            fields["_web_url"] = item.get("webUrl")
            rows.append(fields)
        url = payload.get("@odata.nextLink")
    df = pd.DataFrame(rows)
    print(f"{list_name}: {len(df)} lignes, {len(df.columns)} colonnes")
    return df


df_documents = fetch_list_items(LIST_DOCUMENTS)
df_library   = fetch_list_items(LIST_LIBRARY)

# COMMAND ----------

display(df_documents.head(20))

# COMMAND ----------

display(df_library.head(20))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. DL des fichiers dans le volume
# MAGIC
# MAGIC On passe par le drive (endpoint `/drives/…/content`) plutôt que par la liste,
# MAGIC pour récupérer les binaires directement.

# COMMAND ----------

# Résout le drive de la bibliothèque "Documents"
r = requests.get(f"{GRAPH_ROOT}/sites/{SITE_ID}/drives", headers=GRAPH_HEADERS, timeout=30)
r.raise_for_status()
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
    raise RuntimeError("aucun drive")

# COMMAND ----------

def walk_drive(drive_id, folder_id="root", rel_path=""):
    url = f"{GRAPH_ROOT}/drives/{drive_id}/items/{folder_id}/children?$top=1000"
    while url:
        r = requests.get(url, headers=GRAPH_HEADERS, timeout=60)
        r.raise_for_status()
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


spark.sql(f"CREATE VOLUME IF NOT EXISTS `{CATALOG}`.`{SCHEMA}`.`{VOLUME}`")
os.makedirs(VOLUME_DIR, exist_ok=True)

downloaded = []
for rel, item in walk_drive(DRIVE_ID):
    local_path = os.path.join(VOLUME_DIR, sanitize(rel))
    os.makedirs(os.path.dirname(local_path), exist_ok=True)
    dl_url = f"{GRAPH_ROOT}/drives/{DRIVE_ID}/items/{item['id']}/content"
    with requests.get(dl_url, headers=GRAPH_HEADERS, stream=True, timeout=120) as r:
        r.raise_for_status()
        with open(local_path, "wb") as f:
            for chunk in r.iter_content(chunk_size=1 << 20):
                if chunk:
                    f.write(chunk)
    downloaded.append({
        "sharepoint_id": item["id"],
        "name": item["name"],
        "rel_path": rel,
        "local_path": local_path,
        "size": item.get("size"),
    })
    print(f"  ↓ {rel} ({item.get('size')} B)")

print(f"{len(downloaded)} fichiers dans {VOLUME_DIR}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Push vers S3

# COMMAND ----------

s3 = boto3.client("s3", region_name=AWS_REGION)
uploaded = []
for f in downloaded:
    key = f"{S3_PREFIX}{f['rel_path']}"
    s3.upload_file(f["local_path"], S3_BUCKET, key)
    uploaded.append({**f, "s3_key": key})
    print(f"  ↑ s3://{S3_BUCKET}/{key}")
print(f"{len(uploaded)} fichiers sur s3://{S3_BUCKET}/{S3_PREFIX}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Ping RDS
# MAGIC
# MAGIC Table dédiée `infra_test_ping` pour ne pas toucher aux tables métier (FK).

# COMMAND ----------

conn = psycopg2.connect(
    host=RDS_HOST, port=RDS_PORT, dbname=RDS_DB,
    user=RDS_USER, password=RDS_PASSWORD, connect_timeout=10,
)
try:
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS public.infra_test_ping (
                id uuid PRIMARY KEY,
                note text NOT NULL,
                ts  timestamptz NOT NULL DEFAULT now()
            );
        """)
        ping_id = str(uuid.uuid4())
        note = json.dumps({
            "source": "opex_data/test_infra.py",
            "documents_rows": len(df_documents),
            "library_rows": len(df_library),
            "files_uploaded": len(uploaded),
            "bucket": S3_BUCKET,
        })
        cur.execute(
            "INSERT INTO public.infra_test_ping (id, note, ts) VALUES (%s, %s, %s)",
            (ping_id, note, datetime.now(timezone.utc)),
        )
    conn.commit()
    print(f"ping insert OK id={ping_id}")
finally:
    conn.close()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Récap

# COMMAND ----------

summary = {
    "sharepoint": {"documents_rows": len(df_documents), "library_rows": len(df_library)},
    "volume":      VOLUME_DIR,
    "files_dl":    len(downloaded),
    "s3_target":   f"s3://{S3_BUCKET}/{S3_PREFIX}",
    "files_up":    len(uploaded),
    "rds_ping_id": ping_id,
    "run_at":      datetime.now(timezone.utc).isoformat(),
}
print(json.dumps(summary, indent=2))
dbutils.notebook.exit(json.dumps(summary))
