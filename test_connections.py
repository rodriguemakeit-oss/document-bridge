# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — Test connexions SharePoint / S3
# MAGIC
# MAGIC Ne copie rien. Sert uniquement à valider, avant le run complet
# MAGIC ([sharepoint_to_s3.py](sharepoint_to_s3.py)) :
# MAGIC 1. l'auth Microsoft Graph et la lecture du site/drive SharePoint (liste les fichiers)
# MAGIC 2. l'accès en lecture ET écriture au bucket S3 depuis ce compute, via `dbutils.fs`
# MAGIC    (pas `boto3` : en serverless il n'y a pas d'instance profile, l'accès S3 passe
# MAGIC    par Unity Catalog)

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
# MAGIC Mêmes valeurs que [sharepoint_to_s3.py](sharepoint_to_s3.py). Creds via `.env`
# MAGIC en local (voir `.env.example`), ou variables d'env / secret scope sur Databricks.

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

# S3 — accès via dbutils.fs (Unity Catalog external location, pas de creds AWS ici)
S3_BUCKET  = "demo-document-bucket"
S3_PREFIX  = "sharepoint/"

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
print("✓ token Graph OK")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Site + drive SharePoint

# COMMAND ----------

r = requests.get(
    f"{GRAPH_ROOT}/sites/{SHAREPOINT_HOST}:{SHAREPOINT_SITE_PATH}",
    headers=GRAPH_HEADERS, timeout=30,
)
r.raise_for_status()
SITE_ID = r.json()["id"]
print(f"✓ site_id = {SITE_ID}")

r = requests.get(f"{GRAPH_ROOT}/sites/{SITE_ID}/drives", headers=GRAPH_HEADERS, timeout=30)
r.raise_for_status()
drives = r.json().get("value", [])
print(f"  {len(drives)} drive(s) trouvé(s) : {[d.get('name') for d in drives]}")

DRIVE_ID = None
for d in drives:
    if d.get("name") in {LIST_DOCUMENTS, "Documents", "Documents partagés", "Shared Documents"}:
        DRIVE_ID = d["id"]
        print(f"✓ drive '{d['name']}' → {DRIVE_ID}")
        break
if not DRIVE_ID and drives:
    DRIVE_ID = drives[0]["id"]
    print(f"  fallback drive: {drives[0]['name']}")
if not DRIVE_ID:
    raise RuntimeError("aucun drive trouvé")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Liste des fichiers (pas de téléchargement)

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


files = list(walk_drive(DRIVE_ID))
total_size = sum(item.get("size", 0) for _, item in files)

print(f"✓ {len(files)} fichier(s) trouvé(s), {total_size / 1_048_576:.1f} MB au total\n")
for rel, item in files[:20]:
    print(f"  - {rel} ({item.get('size')} B)")
if len(files) > 20:
    print(f"  ... et {len(files) - 20} de plus")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Accès S3 (lecture + écriture)

# COMMAND ----------

def sanitize(path: str) -> str:
    return re.sub(r"[^\w\-./ ()]+", "_", path)


s3_root = f"s3://{S3_BUCKET}/{S3_PREFIX}"

# Diagnostic : le bucket est-il connu de Unity Catalog en tant qu'External Location ?
# (si l'écriture plus bas échoue avec "AnonymousAWSCredentials", c'est probablement
# qu'aucune ligne ci-dessous ne couvre s3_root, ou que tu n'as pas la permission dessus)
locations = spark.sql("SHOW EXTERNAL LOCATIONS").toPandas()
print("External locations visibles pour toi :")
print(locations[["name", "url"]].to_string(index=False) if len(locations) else "  (aucune)")

# Lecture : lister ce qui existe déjà sous le préfixe (peut ne rien renvoyer si vide)
try:
    existing = dbutils.fs.ls(s3_root)
    print(f"✓ lecture OK : {len(existing)} objet(s) sous {s3_root}")
    for f in existing[:5]:
        print(f"  - {f.path} ({f.size} B)")
except Exception as e:
    print(f"  rien sous {s3_root} pour l'instant (ou erreur) : {e}")

# Écriture : dépose + suppression d'un objet de test
test_path = f"{s3_root}_connectivity_test.txt"
dbutils.fs.put(test_path, "ping depuis Databricks", overwrite=True)
print(f"✓ écriture OK : {test_path}")

dbutils.fs.rm(test_path)
print("✓ suppression OK (nettoyage de l'objet de test)")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Récap

# COMMAND ----------

summary = {
    "graph_auth": "OK",
    "site_id": SITE_ID,
    "drive_id": DRIVE_ID,
    "sharepoint_files_found": len(files),
    "sharepoint_total_size_mb": round(total_size / 1_048_576, 1),
    "s3_bucket": S3_BUCKET,
    "s3_read": "OK",
    "s3_write": "OK",
}
print(summary)
print("\nTout est vert → prêt pour sharepoint_to_s3.py")
