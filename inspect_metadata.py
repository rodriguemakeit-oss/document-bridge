# Databricks notebook source
# MAGIC %md
# MAGIC # OpEx — Inspection des métadonnées SharePoint
# MAGIC
# MAGIC Récupère UN document de la liste `Documents` et affiche toutes ses colonnes
# MAGIC (`fields`) telles que Graph les renvoie — sert juste à voir les noms de colonnes
# MAGIC réels (assessment_id, element, etc.) avant d'écrire le script définitif.
# MAGIC Ne touche pas à S3.

# COMMAND ----------

# MAGIC %pip install --quiet msal python-dotenv

# COMMAND ----------

import json
import os

import msal
import requests
from dotenv import load_dotenv

load_dotenv()  # no-op sur Databricks (pas de .env), utile en local

# COMMAND ----------

def env(key: str) -> str:
    v = os.environ.get(key, "")
    if not v:
        raise RuntimeError(f"env var manquante: {key}")
    return v

# Microsoft Graph (app registration Azure AD, tenant portfolio), via .env / variables d'env
GRAPH_TENANT_ID     = env("GRAPH_TENANT_ID")
GRAPH_CLIENT_ID     = env("GRAPH_CLIENT_ID")
GRAPH_CLIENT_SECRET = env("GRAPH_CLIENT_SECRET")

SHAREPOINT_HOST      = "example.sharepoint.com"
SHAREPOINT_SITE_PATH = "/sites/OperationalExcellenceGlobal"
LIST_DOCUMENTS       = "Documents"

# Combien d'items regarder (le premier "vrai" document, dossiers ignorés)
N_SAMPLES = 1

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

r = requests.get(
    f"{GRAPH_ROOT}/sites/{SHAREPOINT_HOST}:{SHAREPOINT_SITE_PATH}",
    headers=GRAPH_HEADERS, timeout=30,
)
r.raise_for_status()
SITE_ID = r.json()["id"]
print(f"site_id = {SITE_ID}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Colonnes déclarées sur la liste (les libellés visibles à l'écran)

# COMMAND ----------

r = requests.get(
    f"{GRAPH_ROOT}/sites/{SITE_ID}/lists/{LIST_DOCUMENTS}/columns",
    headers=GRAPH_HEADERS, timeout=30,
)
r.raise_for_status()
columns = r.json().get("value", [])
print(f"{len(columns)} colonnes déclarées sur la liste :\n")
for c in columns:
    if c.get("readOnly") or c.get("hidden"):
        continue
    print(f"  - name (interne) = {c.get('name'):30s} displayName = {c.get('displayName')}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Contenu réel d'un (ou plusieurs) document(s)

# COMMAND ----------

r = requests.get(
    f"{GRAPH_ROOT}/sites/{SITE_ID}/lists/{LIST_DOCUMENTS}/items?expand=fields&$top=50",
    headers=GRAPH_HEADERS, timeout=60,
)
r.raise_for_status()
items = r.json().get("value", [])

shown = 0
for item in items:
    fields = item.get("fields", {}) or {}
    if fields.get("FSObjType") == "1":  # dossier, on saute
        continue
    print(f"\n=== item id={item.get('id')} — {fields.get('FileLeafRef')} ===")
    print(json.dumps(fields, indent=2, ensure_ascii=False))
    shown += 1
    if shown >= N_SAMPLES:
        break

if shown == 0:
    print("Aucun document (non-dossier) trouvé dans les 50 premiers items.")
