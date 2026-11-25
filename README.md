# Document Bridge

A reference workflow for transferring documents and associated metadata between collaboration storage, object storage, and a relational database.

## What it demonstrates

- Microsoft Graph authentication through environment-based secrets
- Document and metadata extraction as separate steps
- Object-storage paths that preserve source hierarchy
- Relational metadata reconciliation

## Repository map

- `sharepoint_to_s3.py` — document transfer example
- `sharepoint_metadata_to_s3.py` — metadata export example
- `schema_db.sql` — relational schema
- `test_connections.py` — connectivity checks

## Before running

See [GUIDE.md](GUIDE.md) and configure your own tenant, storage, database, and access policies. The repository contains no document corpus or credentials; example hostnames and settings are placeholders.

## Scope

This portfolio adaptation illustrates integration patterns. It is not a production migration tool: review permissions, retention, error handling, and destination controls for your use case. See [VALIDATION.md](VALIDATION.md).