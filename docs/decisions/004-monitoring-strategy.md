# ADR-004: Stratégie de Monitoring et Observabilité

## Statut
Accepté

## Contexte
Pour comparer objectivement les deux architectures, nous devons décider entre des dashboards CloudWatch unifiés ou séparés, tout en considérant l'isolation des environnements et la simplicité de déploiement.

## Options Considérées

### Option 1: Dashboard Unifié (rejetée)
- Dashboard partagé dans l'environnement "shared"
- Cross-references vers les métriques des deux architectures
- Vue comparative directe

### Option 2: Dashboards Séparés (choisie)
- Dashboard dédié par architecture
- Isolation complète des environnements
- Comparaison par ouverture simultanée

### Option 3: Dashboard Externe
- Grafana ou Datadog
- Agrégation multi-sources
- Complexité supplémentaire

## Décision

**Dashboards CloudWatch séparés** par architecture avec nomenclature cohérente pour faciliter la comparaison.

- `classique-dashboard`: Métriques ALB, ASG, RDS
- `serverless-dashboard`: Métriques Lambda, CloudFront, Aurora

## Justification

### Avantages des Dashboards Séparés

**Isolation Architecturale**
- Aucune dépendance croisée entre environnements
- Déploiement/destruction indépendants
- Sécurité renforcée (permissions par environnement)

**Simplicité Terraform**
- Pas de remote state cross-références complexes
- Modules autonomes sans couplage
- Évite les circular dependencies

**Maintenance Opérationnelle**
- Un problème sur une architecture n'affecte pas l'autre
- Débugging isolé par stack
- Rollback indépendant possible

### Inconvénients Acceptés

**Comparaison Manuelle**
- Nécessite d'ouvrir deux dashboards simultanément
- Pas de vue unifiée automatique
- Corrélation temporelle manuelle

**Duplication de Configuration**
- Widgets similaires définis deux fois
- Maintenance de cohérence entre dashboards

## Métriques par Architecture

### Dashboard Classique
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_arn_suffix}"],
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${alb_arn_suffix}"]
        ],
        "title": "ALB - Performance"
      }
    },
    {
      "type": "metric", 
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${asg_name}"]
        ],
        "title": "Auto Scaling Group - CPU"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${rds_instance_id}"],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${rds_instance_id}"]
        ],
        "title": "RDS - CPU & Connections"
      }
    }
  ]
}
```

### Dashboard Serverless
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Lambda", "Duration", "FunctionName", "${lambda_function_name}"],
          ["AWS/Lambda", "Invocations", "FunctionName", "${lambda_function_name}"],
          ["AWS/Lambda", "Errors", "FunctionName", "${lambda_function_name}"]
        ],
        "title": "Lambda - Performance"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/CloudFront", "Requests", "DistributionId", "${distribution_id}"]
        ],
        "title": "CloudFront - Requests"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", "${aurora_cluster_id}"],
          ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", "${aurora_cluster_id}"]
        ],
        "title": "Aurora - ACU & Connections"
      }
    }
  ]
}
```

## Stratégie de Comparaison

### Méthode Actuelle
1. Ouvrir simultanément les deux dashboards
2. Synchroniser les plages temporelles
3. Exporter les métriques pour analyse comparative
4. Screenshots côte-à-côte pour documentation

### Méthode Future (Terraform Cloud)
Avec Terraform Cloud/Enterprise :
- Workspaces centralisés
- Cross-workspace data sources
- Dashboard unifié possible via remote state sharing
- Pipeline CI/CD coordonné

## Conséquences

### Positives
- **Déploiement simple**: Chaque stack reste autonome
- **Sécurité**: Isolation des permissions par environnement
- **Maintenance**: Pas de couplage complexe entre environnements
- **Évolutivité**: Ajout facile de nouvelles architectures

### Négatives
- **Expérience utilisateur**: Comparaison manuelle nécessaire
- **Corrélation**: Pas de vue unifiée automatique
- **Maintenance**: Cohérence à maintenir manuellement

## Métriques de Validation
- Temps de déploiement des dashboards
- Facilité de debugging par environnement
- Qualité de la comparaison des performances
- Complexité opérationnelle

## Évolution Prévue
Cette approche représente une étape intermédiaire avant :
- Migration vers Terraform Cloud avec workspaces centralisés
- Dashboard unifié via data sources cross-workspace
- Observabilité unifiée avec outils tiers (Grafana, Datadog)

## Révision
Cette décision sera réévaluée si :
- Migration vers Terraform Cloud/Enterprise
- Complexité de comparaison devient bloquante
- Besoin d'observabilité temps réel unifiée