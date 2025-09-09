# ADR-003: Stratégies Réseau et Connectivité

## Statut
Accepté

## Contexte
Les architectures classique et serverless ont des besoins réseau différents. Les choix de connectivité impactent directement les coûts, la sécurité et les performances de chaque approche.

## Options Considérées

### Architecture Classique - Connectivité Sortante
1. **NAT Gateway** (choisi)
2. NAT Instance
3. Internet Gateway direct (public)
4. VPC Endpoints seulement

### Architecture Serverless - Connectivité Sortante
1. **VPC Endpoints** (choisi)
2. NAT Gateway
3. Pas de VPC (Lambda public)
4. Hybride NAT + VPC Endpoints

### Gestion des Secrets
1. **Secrets Manager avec VPC Endpoints** (choisi)
2. Environment variables Lambda
3. Parameter Store
4. KMS + S3

## Décision

**Classique**: Subnets privés → NAT Gateway → Internet Gateway
**Serverless**: Subnets privés → VPC Endpoints (S3, Secrets Manager, CloudWatch Logs)

## Justification

### NAT Gateway pour Classique
- **Représentatif**: Pattern standard pour EC2 en production
- **Simplicité**: Une solution pour tous les besoins sortants
- **Performance**: Débit garanti (5-45 Gbps)
- **Maintenance**: Managé AWS, pas d'instance à maintenir

### VPC Endpoints pour Serverless
- **Optimisation coût**: Pas de NAT Gateway inutile (45$/mois fixe)
- **Sécurité**: Trafic ne sort jamais du réseau AWS
- **Performance**: Latence réduite vers services AWS
- **Pattern cloud-native**: Optimisation spécifique aux services managés

### Pourquoi pas NAT pour Serverless
- **Surconsommation**: Lambda n'a pas besoin d'internet général
- **Coût fixe**: NAT Gateway coûte plus cher que les VPC Endpoints
- **Sécurité**: Attack surface réduite sans accès internet

### Pourquoi pas VPC Endpoints pour Classique
- **Complexité**: EC2 peut avoir besoin d'accès internet varié
- **Coût**: Multiples endpoints vs un seul NAT Gateway
- **Flexibilité**: NAT permet tout accès sortant

## Architecture Réseau Détaillée

### Classique
```
Internet Gateway
    ↓
Public Subnet (ALB)
    ↓
Private Subnet (EC2) → NAT Gateway → Updates, APIs externes
    ↓
Private Subnet (RDS)
```

### Serverless
```
CloudFront (Global)
    ↓
S3 Bucket (Public read via OAI)
    ↓
API Gateway (Public)
    ↓
Private Subnet (Lambda) → VPC Endpoints → AWS Services uniquement
    ↓
Private Subnet (Aurora)
```

## Conséquences

### Coût Mensuel
**Classique**:
- NAT Gateway: 45€/mois + data processing
- Total connectivité: ~50€/mois

**Serverless**:
- VPC Endpoints (3x): ~20€/mois
- Total connectivité: ~20€/mois

### Sécurité
**Classique**:
- EC2 peut accéder à internet (via NAT)
- Contrôle par Security Groups
- Logs VPC Flow

**Serverless**:
- Lambda isolé (seulement AWS services)
- Zero accès internet sortant
- Audit trail complet

### Performance
**Classique**:
- Latence NAT: ~1-2ms
- Débit: Pas de limitation pratique

**Serverless**:
- Latence VPC Endpoints: ~0.5ms
- Débit: Optimisé par AWS

## Métriques de Validation
- Coût mensuel de connectivité
- Latence d'accès aux services AWS
- Temps de déploiement/mise à jour
- Incidents de sécurité

## Limitations Identifiées

### Classique
- Coût fixe NAT même sans trafic
- Point unique de défaillance (mitigé par multi-AZ)

### Serverless
- Besoin d'ajouter des endpoints pour nouveaux services AWS
- Pas d'accès internet général (limitation volontaire)

## Révision
Cette décision sera réévaluée si :
- AWS introduit des NAT Gateway serverless
- Les coûts des VPC Endpoints changent significativement
- Lambda nécessite un accès internet pour des intégrations tierces