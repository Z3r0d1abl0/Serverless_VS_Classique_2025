ADR-004: Stratégie de Monitoring et Observabilité
Statut
Accepté
Contexte
Pour comparer objectivement les architectures, il faut décider entre dashboards CloudWatch unifiés ou séparés, en considérant l'isolation des environnements et la simplicité opérationnelle.
Options Considérées

Dashboard unifié - Vue comparative directe mais couplage des environnements
Dashboards séparés (choisi) - Isolation complète, comparaison manuelle
Solution externe - Grafana/Datadog mais complexité supplémentaire

Décision
Dashboards CloudWatch séparés par architecture:

classique-dashboard: Métriques ALB, ASG, RDS
serverless-dashboard: Métriques Lambda, CloudFront, Aurora

Justification
Dashboards Séparés:

Isolation architecturale: Aucune dépendance croisée entre environnements
Simplicité Terraform: Pas de remote state cross-references complexes
Déploiement indépendant: Destruction d'un environnement n'affecte pas l'autre
Sécurité: Permissions par environnement, principe du moindre privilège

Trade-off Accepté:

Comparaison manuelle: Nécessite d'ouvrir deux dashboards simultanément
Corrélation temporelle: Synchronisation manuelle des time ranges

Métriques par Architecture
Dashboard Classique:

ALB: TargetResponseTime, RequestCount, HTTPCode_Target_2XX_Count
Auto Scaling Group: CPUUtilization, GroupDesiredCapacity
RDS: CPUUtilization, DatabaseConnections, ReadLatency

Dashboard Serverless:

Lambda: Duration, Invocations, Errors, ConcurrentExecutions
CloudFront: Requests, BytesDownloaded, OriginLatency
Aurora: ServerlessDatabaseCapacity, DatabaseConnections, SelectLatency

Stratégie de Comparaison

Synchroniser les time ranges sur les deux dashboards
Tests de charge coordonnés avec timestamps
Export des métriques pour analyse comparative
Screenshots côte-à-côte pour documentation

Conséquences
Positives:

Simplicité opérationnelle: Chaque stack reste autonome
Évolutivité: Ajout facile de nouvelles architectures
Debugging isolé: Problème sur une architecture n'affecte pas l'autre

Négatives:

Expérience utilisateur: Comparaison moins fluide
Maintenance: Cohérence à maintenir manuellement entre dashboards
