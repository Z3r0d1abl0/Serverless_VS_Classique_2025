# Guide de Troubleshooting - AWS Architecture Comparison

## Problèmes Terraform Courants

### 1. Gestion des États Terraform
**Problème**: États mélangés entre environnements, verrouillage DynamoDB

**Symptômes**:
```bash
Error: Error acquiring the state lock
Error: Backend configuration changed
```

**Solutions**:
```bash
# Forcer le déverrouillage (avec précaution)
terraform force-unlock <LOCK_ID>

# Vérifier la configuration backend
terraform init -reconfigure

# Nettoyer les états orphelins
aws dynamodb delete-item \
  --table-name terraform-state-locks \
  --key '{"LockID":{"S":"<path-to-state>"}}'
```

**Prévention**:
- Toujours utiliser des workspaces/backends séparés
- Vérifier `backend.tf` avant `terraform init`
- Ne jamais lancer plusieurs `terraform apply` simultanés

### 2. Dépendances Circulaires Security Groups
**Problème**: Security Groups qui se référencent mutuellement

**Symptômes**:
```bash
Error: Cycle: aws_security_group.rds_sg, aws_security_group.ec2_sg
```

**Solutions**:
```bash
# Option 1: Utiliser aws_security_group_rule séparées
resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port               = 3306
  to_port                 = 3306
  protocol                = "tcp"
  source_security_group_id = aws_security_group.ec2_sg.id
  security_group_id       = aws_security_group.rds_sg.id
}

# Option 2: Créer les SG d'abord, puis les règles
terraform apply -target=aws_security_group.rds_sg
terraform apply
```

### 3. IAM Roles EntityAlreadyExists
**Problème**: Tentative de création de rôles IAM existants

**Symptômes**:
```bash
Error: EntityAlreadyExistsException: Role with name XYZ already exists
```

**Solutions**:
```bash
# Import du rôle existant
terraform import aws_iam_role.existing_role role-name

# Ou suppression manuelle (si safe)
aws iam delete-role --role-name problematic-role

# Vérifier les politiques attachées d'abord
aws iam list-attached-role-policies --role-name role-name
```

## Problèmes Réseau et Connectivité

### 4. VPC Endpoints et NAT Gateway
**Problème**: Confusion entre stratégies de connectivité sortante

**Symptômes**:
- Lambda timeout sur appels AWS services
- EC2 ne peut pas accéder à internet
- Coûts NAT Gateway élevés pour serverless

**Solutions**:
```bash
# Vérifier les routes
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=vpc-xxxxx"

# Tester connectivité depuis EC2
aws ssm start-session --target i-xxxxx
curl -I https://s3.eu-west-3.amazonaws.com

# Vérifier VPC Endpoints status
aws ec2 describe-vpc-endpoints
```

**Architecture correcte**:
- **Classique**: Private subnets → NAT Gateway → Internet
- **Serverless**: Private subnets → VPC Endpoints → AWS Services

### 5. Security Groups et Health Checks
**Problème**: Instances ALB en état "Unhealthy"

**Symptômes**:
```bash
# CloudWatch logs ALB
Target.FailedHealthChecks: Health checks failed
```

**Solutions**:
```bash
# Vérifier les security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Tester health check manuellement
curl -I http://instance-ip/health

# Vérifier la configuration ALB target group
aws elbv2 describe-target-health --target-group-arn arn:aws:elasticloadbalancing:...
```

**Checklist Health Checks**:
- Port correct dans security group (80/443)
- Path health check accessible (/health)
- Timeout suffisant (5-30 secondes)
- Instance en cours d'exécution

## Problèmes Certificats et DNS

### 6. ACM et CloudFront
**Problème**: Certificats ACM non valides pour CloudFront

**Symptômes**:
```bash
Error: The certificate must be in us-east-1 region
```

**Solutions**:
```bash
# Provider AWS alias pour us-east-1
provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

# Certificat dans la bonne région
resource "aws_acm_certificate" "cloudfront" {
  provider    = aws.useast1
  domain_name = "serverless.example.com"
}
```

### 7. Route 53 Validation DNS
**Problème**: Validation ACM qui échoue

**Symptômes**:
- Certificat reste en "Pending Validation"
- Timeout après 45 minutes

**Solutions**:
```bash
# Vérifier les enregistrements DNS
dig _validation-hash.domain.com CNAME

# Forcer la re-création des enregistrements
terraform taint aws_route53_record.validation
terraform apply
```

## Problèmes Application

### 8. CORS et API Gateway
**Problème**: Erreurs CORS entre frontend et API

**Symptômes**:
```javascript
Access-Control-Allow-Origin header is missing
```

**Solutions**:
```python
# Lambda response headers
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': 'https://serverless.domain.com',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization'
        },
        'body': json.dumps(data)
    }
```

### 9. Cold Start Lambda
**Problème**: Latence élevée sur première requête

**Symptômes**:
- Temps de réponse > 1000ms sporadiquement
- Timeout sur Lambda

**Solutions**:
```python
# Initialisation hors handler
import json
import boto3

# Connexions réutilisables
rds_client = boto3.client('rds')
secrets_client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    # Handler optimisé
    pass
```

## Nettoyage et Destruction

### 10. Ressources Orphelines
**Problème**: Terraform destroy échoue sur ENI/VPC Endpoints

**Symptômes**:
```bash
Error: DependencyViolation: Network interface is currently in use
```

**Solutions**:
```bash
#!/bin/bash
# Script de nettoyage force
VPC_ID="vpc-xxxxx"

# Détacher les ENI
aws ec2 describe-network-interfaces \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'NetworkInterfaces[?Status==`in-use`].NetworkInterfaceId' \
  --output text | xargs -I {} aws ec2 detach-network-interface --network-interface-id {}

# Supprimer les VPC Endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'VpcEndpoints[].VpcEndpointId' \
  --output text | xargs -I {} aws ec2 delete-vpc-endpoint --vpc-endpoint-id {}

# Attendre et re-lancer destroy
sleep 60
terraform destroy
```

## Monitoring et Debugging

### 11. CloudWatch Métriques Manquantes
**Problème**: Dashboards affichent "No data available"

**Symptômes**:
- Métriques RDS/Aurora absentes
- Dimensions incorrectes

**Solutions**:
```bash
# Vérifier les métriques disponibles
aws cloudwatch list-metrics --namespace AWS/RDS

# Corriger les dimensions
# RDS: DBInstanceIdentifier
# Aurora: DBClusterIdentifier

# Forcer la génération de métriques
aws rds describe-db-instances
aws rds describe-db-clusters
```

## Checklist de Validation Post-Déploiement

### Architecture Classique
- [ ] ALB répond sur HTTPS
- [ ] Health checks EC2 OK
- [ ] RDS accessible depuis EC2
- [ ] Métriques CloudWatch visibles
- [ ] Tests de charge fonctionnels

### Architecture Serverless
- [ ] CloudFront distribution active
- [ ] API Gateway accessible
- [ ] Lambda s'exécute sans erreur
- [ ] Aurora Serverless scaling
- [ ] VPC Endpoints fonctionnels

### Commandes de Validation
```bash
# Test des endpoints
curl -I https://classique.domain.com/health
curl -I https://serverless.domain.com/api/db-test

# Vérification des logs
aws logs describe-log-groups
aws logs tail /aws/lambda/function-name

# Status des services
aws elbv2 describe-target-health --target-group-arn ...
aws rds describe-db-clusters --db-cluster-identifier ...
```