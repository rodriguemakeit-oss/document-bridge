# Document Bridge

Migration de documents et métadonnées de SharePoint vers S3 et PostgreSQL.

Version de portfolio maintenue sur [rodriguemakeit-oss](https://github.com/rodriguemakeit-oss).

## Ce que le projet explore

Migration de documents et métadonnées de SharePoint vers S3 et PostgreSQL. L’accent est mis sur la séparation des composants, la configuration explicite et la réutilisation des traitements.

## Structure

`sharepoint_to_s3.py · sharepoint_metadata_to_s3.py · schema_db.sql`

## Prise en main

Copiez `.env.example` vers `.env`, renseignez vos accès puis lancez les scripts de migration.

Les valeurs de déploiement sont des exemples. Les identifiants nuls et les domaines `example.invalid` doivent être remplacés dans votre propre environnement. Aucun déploiement cloud n’est lancé automatiquement.

## État du projet

Cette adaptation nécessite vos propres services et jeux de données. Les contrôles locaux sont décrits dans [VALIDATION.md](VALIDATION.md) ; ils ne constituent pas une validation des intégrations cloud.

## Contributions et licences

Les noms de packages, crédits d’auteurs et avis tiers conservés dans les sources s’appliquent à leurs composants respectifs. Aucune licence globale supplémentaire n’est attribuée à ce dépôt.
