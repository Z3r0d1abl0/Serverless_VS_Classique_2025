# ADR-001: Choix des Technologies de Base de Données

## Statut
Accepté

## Contexte
Pour comparer objectivement les architectures classique et serverless, nous devons choisir des technologies de base de données représentatives de chaque approche tout en gardant une charge de travail comparable.

## Options Considérées

### Architecture Classique
1. **RDS MySQL** (choisi)
2. RDS PostgreSQL
3. EC2 avec MySQL auto-géré

### Architecture Serverless
1. **Aurora Serverless v2** (choisi)
2. Aurora Serverless v1
3. DynamoDB
4. RDS Proxy + RDS

## Décision

**Classique**: RDS MySQL t3.medium multi-AZ
**Serverless**: Aurora Serverless v2 MySQL (0.5-4 ACU)

## Justification

### RDS MySQL Classique
- **Prévisibilité**: Coût et performance fixes, faciles à budgétiser
- **Maturité**: Technologie éprouvée avec expertise répandue
- **Multi-AZ**: Haute disponibilité intégrée
- **Monitoring**: Métriques CloudWatch standardisées

### Aurora Serverless v2 vs v1
- **v2 avantages**: Pas de pause automatique, scaling plus granulaire (0.5 ACU vs 1 ACU)
- **v2 avantages**: Scaling en secondes vs minutes pour v1
- **v2 inconvénient**: Coût minimal plus élevé (0.5 ACU permanent vs pause complète v1)

### Aurora v2 vs DynamoDB
- **Similarité de workload**: MySQL permet la même logique applicative
- **Comparaison équitable**: Même requêtes SQL sur les deux architectures
- **Learning curve**: DynamoDB nécessiterait une réécriture complète

## Conséquences

### Positives
- Comparaison directe des modèles économiques (fixe vs usage)
- Même charge de travail applicative sur les deux architectures
- Métriques CloudWatch comparables (temps de connexion, requêtes/sec)

### Négatives
- Aurora v2 a un coût minimal incompressible (0.5 ACU = ~35€/mois)
- Ne représente pas les patterns NoSQL natifs cloud
- Complexité réseau supplémentaire (VPC endpoints pour Aurora)

## Métriques de Validation
- Temps de réponse des requêtes SQL
- Coût par requête exécutée
- Temps de scaling sous charge
- Disponibilité (uptime)

## Révision
Cette décision sera réévaluée si :
- Aurora Serverless v3 est disponible
- Les coûts v2 changent significativement
- Un pattern NoSQL devient nécessaire pour la démonstration