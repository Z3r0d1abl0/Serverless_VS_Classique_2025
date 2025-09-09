# ADR-002: Stratégies de Compute et Frontend

## Statut
Accepté

## Contexte
La comparaison d'architectures nécessite des choix de compute et de distribution frontend représentatifs des paradigmes classique et cloud-native, tout en maintenant une charge applicative similaire.

## Options Considérées

### Architecture Classique - Compute
1. **EC2 Auto Scaling Group** (choisi)
2. EC2 instances fixes
3. ECS avec EC2
4. Fargate

### Architecture Classique - Frontend
1. **ALB direct vers EC2** (choisi)
2. CloudFront + ALB
3. API Gateway + EC2

### Architecture Serverless - Compute
1. **Lambda** (choisi)
2. Fargate serverless
3. ECS avec Fargate Spot

### Architecture Serverless - Frontend
1. **CloudFront + S3** (choisi)
2. S3 website direct
3. API Gateway + CloudFront

## Décision

**Classique**: ALB → Auto Scaling Group (EC2 t3.small) → RDS
**Serverless**: CloudFront + S3 → API Gateway → Lambda → Aurora

## Justification

### Auto Scaling Group vs EC2 fixe
- **Élasticité**: Démonstration des capacités de scaling (même si plus lent que serverless)
- **Haute disponibilité**: Multi-AZ automatique
- **Coût**: Adaptation à la charge (avec limites min/max)
- **Représentatif**: Pattern standard en production

### ALB vs CloudFront pour le classique
- **Simplicité**: ALB suffit pour démontrer le pattern classique
- **Coût**: Pas de surcoût CloudFront inutile
- **Latence**: Une couche de moins dans la comparaison
- **Focus**: Concentration sur compute/database plutôt que CDN

### Lambda vs Fargate
- **Serverless pur**: Lambda représente mieux le paradigme serverless
- **Cold start**: Démonstration des trade-offs serverless
- **Granularité**: Facturation à la requête vs container-time
- **Simplicité**: Pas de gestion de containers

### CloudFront + S3 vs ALB pour serverless
- **Pattern cloud-native**: Séparation statique/dynamique
- **Performance**: CDN global pour assets statiques
- **Coût**: Optimisation par type de contenu
- **Scalabilité**: Distribution géographique automatique

## Conséquences

### Positives
- **Comparaison équitable**: Chaque architecture utilise ses patterns optimaux
- **Métriques distinctes**: ALB vs CloudFront offrent des métriques différentes mais comparables
- **Élasticité différentielle**: Démonstration claire des différences de scaling
- **Coûts représentatifs**: Modèles économiques authentiques

### Négatives
- **Complexité asymétrique**: Serverless a plus de services (S3, CloudFront, API Gateway, Lambda)
- **Debugging différent**: Logs ALB vs traces distribuées
- **Cold start impact**: Lambda pénalisé sur premier appel
- **Learning curve**: Serverless nécessite plus de compétences cloud

## Patterns de Charge

### Scaling Classique
- **Trigger**: CPU > 70% pendant 2 minutes
- **Action**: Ajout d'instance EC2 (3-5 minutes)
- **Coût**: Instance complète facturée

### Scaling Serverless
- **Trigger**: Requête entrante
- **Action**: Lambda concurrent (< 10 secondes)
- **Coût**: Millisecondes d'exécution

## Métriques de Validation
- Temps de réponse sous charge
- Temps de scaling (0 à pic de trafic)
- Coût par requête servie
- Disponibilité durant les pics

## Révision
Cette décision sera réévaluée si :
- ECS Fargate devient plus cost-effective que Lambda
- Les patterns containers serverless évoluent significativement
- Les cold starts Lambda deviennent négligeables