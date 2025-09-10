ADR-001: Choix des Technologies de Base de Données
Statut
Accepté
Contexte
Pour comparer objectivement les architectures classique et serverless, il faut choisir des technologies de base de données représentatives de chaque approche tout en maintenant une charge de travail comparable.
Options Considérées
Architecture Classique:

RDS MySQL (choisi) - Modèle traditionnel avec sizing fixe
RDS PostgreSQL - Fonctionnalités avancées mais complexité supplémentaire
EC2 avec MySQL auto-géré - Contrôle total mais maintenance élevée

Architecture Serverless:

Aurora Serverless v2 (choisi) - Auto-scaling avec compatibilité MySQL
Aurora Serverless v1 - Pause automatique mais scaling plus lent
DynamoDB - NoSQL natif mais nécessite refonte applicative

Décision

Classique: RDS MySQL t3.medium multi-AZ
Serverless: Aurora Serverless v2 MySQL (0.5-4 ACU)

Justification
RDS MySQL:

Coût prévisible: 85€/mois fixe, budgétisation simple
Performance stable: Pas de variabilité liée au scaling
Multi-AZ: Haute disponibilité avec failover automatique
Opérationnalité: Backup automatisé, maintenance window gérée

Aurora Serverless v2:

Élasticité: Scaling de 0.5 à 4 ACU selon la charge réelle
Pay-per-use: 0.12€/ACU-heure, optimal pour charges variables
Compatibilité: Même requêtes SQL pour comparaison équitable
Scaling rapide: Ajustement en secondes vs minutes pour v1

Conséquences
Positives:

Comparaison directe des modèles économiques (fixe vs usage)
Même logique applicative sur les deux architectures
Métriques CloudWatch comparables (latence, connexions)

Négatives:

Aurora v2 a un coût incompressible (0.5 ACU minimum = ~35€/mois)
Complexité réseau supplémentaire avec VPC endpoints pour Aurora
Ne démontre pas les patterns NoSQL cloud-native

Métriques de Validation

Temps de réponse des requêtes
Coût par transaction
Comportement sous montée de charge
Disponibilité effective