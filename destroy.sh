#!/bin/bash

# Script de destruction intelligent pour S_Vs_C_2025
# Gère les dépendances dans le bon ordre

set -e

echo "🚨 DESTRUCTION INTELLIGENTE DU PROJET S_Vs_C_2025"
echo "=================================================="

read -p "Êtes-vous sûr ? Tapez 'DESTROY' pour confirmer: " confirm
if [ "$confirm" != "DESTROY" ]; then
    echo "❌ Annulé"
    exit 1
fi

# Fonction utilitaire pour attendre qu'une ressource soit supprimée
wait_resource_deletion() {
    local resource_type="$1"
    local check_command="$2"
    local max_wait=60
    local count=0
    
    echo "⏳ Attente suppression $resource_type..."
    while [ $count -lt $max_wait ]; do
        if ! eval "$check_command" >/dev/null 2>&1; then
            echo "✅ $resource_type supprimé"
            return 0
        fi
        sleep 5
        count=$((count + 5))
        echo "   ... $count secondes"
    done
    echo "⚠️ Timeout pour $resource_type"
}

# ===========================================
# 1. DESTRUCTION CIBLÉE SERVERLESS
# ===========================================
echo ""
echo "📂 1. Destruction serverless avec ordre optimisé..."
if [ -d "envs/serverless" ]; then
    cd envs/serverless
    
    if terraform show >/dev/null 2>&1; then
        echo "🎯 1.1. Suppression Lambda et API Gateway..."
        terraform destroy -target=module.lambda_api_gateway.aws_lambda_function.main -auto-approve 2>/dev/null || true
        terraform destroy -target=module.lambda_api_gateway -auto-approve 2>/dev/null || true
        
        # Attendre que les ENI Lambda soient libérées
        sleep 45
        
        echo "🎯 1.2. Suppression VPC Endpoints..."
        terraform destroy -target=module.vpc_endpoints -auto-approve 2>/dev/null || true
        
        sleep 30
        
        echo "🎯 1.3. Suppression Aurora Serverless..."
        terraform destroy -target=module.aurora_serverless -auto-approve 2>/dev/null || true
        
        echo "🎯 1.4. Suppression CloudFront et S3..."
        terraform destroy -target=module.cloudfront -auto-approve 2>/dev/null || true
        terraform destroy -target=module.s3_website -auto-approve 2>/dev/null || true
        
        echo "🎯 1.5. Suppression Security Groups..."
        terraform destroy -target=module.security_groups -auto-approve 2>/dev/null || true
        
        echo "🗑️ 1.6. Destruction complète serverless..."
        terraform destroy -auto-approve || echo "⚠️ Erreur partielle destruction serverless"
    fi
    
    # Nettoyage local
    rm -f terraform.tfstate* .terraform.lock.hcl errored.tfstate
    rm -rf .terraform/
    cd ../..
else
    echo "ℹ️ Dossier serverless non trouvé"
fi

# ===========================================
# 2. NETTOYAGE MANUEL DES ENI LAMBDA
# ===========================================
echo ""
echo "🔌 2. Nettoyage forcé des ENI Lambda..."

# Récupération VPC ID
VPC_ID=$(aws ec2 describe-vpcs --region eu-west-3 \
    --filters "Name=tag:Project,Values=S_Vs_C_2025" \
    --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "")

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo "📋 VPC trouvé : $VPC_ID"
    
    # ENI Lambda spécifiques
    LAMBDA_ENIS=$(aws ec2 describe-network-interfaces --region eu-west-3 \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=description,Values=*Lambda*" \
        --query "NetworkInterfaces[*].NetworkInterfaceId" \
        --output text 2>/dev/null || true)

    if [ -n "$LAMBDA_ENIS" ] && [ "$LAMBDA_ENIS" != "None" ]; then
        echo "🗑️ Suppression ENI Lambda : $LAMBDA_ENIS"
        for eni in $LAMBDA_ENIS; do
            if [ -n "$eni" ] && [ "$eni" != "None" ]; then
                aws ec2 delete-network-interface --network-interface-id "$eni" --region eu-west-3 \
                && echo "✅ ENI $eni supprimée" \
                || echo "⚠️ ENI $eni peut être attachée"
            fi
        done
        sleep 30
    fi
fi

# ===========================================
# 3. DESTRUCTION CIBLÉE CLASSIQUE
# ===========================================
echo ""
echo "📂 3. Destruction classique avec ordre optimisé..."
if [ -d "envs/classique" ]; then
    cd envs/classique

    if terraform show >/dev/null 2>&1; then
        echo "🎯 3.1. Suppression Auto Scaling Group..."
        terraform destroy -target=module.scaling_group -auto-approve 2>/dev/null || true
        
        sleep 30
        
        echo "🎯 3.2. Suppression RDS..."
        terraform destroy -target=module.rds_classique -auto-approve 2>/dev/null || true
        
        echo "🎯 3.3. Suppression ALB..."
        terraform destroy -target=module.alb -auto-approve 2>/dev/null || true
        
        echo "🎯 3.4. Suppression Security Groups..."
        terraform destroy -target=module.security_groups -auto-approve 2>/dev/null || true
        
        echo "🎯 3.5. Suppression Subnets et VPC resources..."
        terraform destroy -target=module.subnet_classique -auto-approve 2>/dev/null || true
        
        echo "🗑️ 3.6. Destruction complète classique..."
        terraform destroy -auto-approve || echo "⚠️ Erreur partielle destruction classique"
    fi

    # Nettoyage local
    rm -f terraform.tfstate* .terraform.lock.hcl errored.tfstate
    rm -rf .terraform/
    cd ../..
else
    echo "ℹ️ Dossier classique non trouvé"
fi

# ===========================================
# 4. NETTOYAGE FORCÉ RESSOURCES AWS PERSISTANTES
# ===========================================
echo ""
echo "🧹 4. Nettoyage forcé des ressources persistantes..."

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    # NAT Gateways
    echo "🌐 4.1. Suppression NAT Gateways..."
    NAT_GWS=$(aws ec2 describe-nat-gateways --region eu-west-3 \
        --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
        --query "NatGateways[*].NatGatewayId" --output text 2>/dev/null || true)
    
    if [ -n "$NAT_GWS" ] && [ "$NAT_GWS" != "None" ]; then
        for nat_gw in $NAT_GWS; do
            if [ -n "$nat_gw" ] && [ "$nat_gw" != "None" ]; then
                aws ec2 delete-nat-gateway --nat-gateway-id "$nat_gw" --region eu-west-3 \
                && echo "✅ NAT Gateway $nat_gw supprimé" \
                || echo "⚠️ Échec suppression NAT Gateway $nat_gw"
            fi
        done
        sleep 60  # NAT Gateways prennent du temps
    fi
    
    # Internet Gateway
    echo "🌐 4.2. Suppression Internet Gateway..."
    IGW_ID=$(aws ec2 describe-internet-gateways --region eu-west-3 \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query "InternetGateways[0].InternetGatewayId" --output text 2>/dev/null || true)
    
    if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region eu-west-3 2>/dev/null || true
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region eu-west-3 \
        && echo "✅ Internet Gateway supprimé" \
        || echo "⚠️ Échec suppression Internet Gateway"
    fi
    
    # Security Groups (ordre inverse de création)
    echo "🔒 4.3. Suppression Security Groups..."
    # D'abord les SG qui référencent d'autres SG
    SG_IDS=$(aws ec2 describe-security-groups --region eu-west-3 \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=*classique*,*serverless*" \
        --query "SecurityGroups[*].GroupId" --output text 2>/dev/null || true)
    
    if [ -n "$SG_IDS" ] && [ "$SG_IDS" != "None" ]; then
        # Première passe : vider les règles qui référencent d'autres SG
        for sg_id in $SG_IDS; do
            if [ -n "$sg_id" ] && [ "$sg_id" != "None" ]; then
                # Supprimer toutes les règles ingress
                aws ec2 describe-security-groups --group-ids "$sg_id" --region eu-west-3 \
                    --query "SecurityGroups[0].IpPermissions" --output json 2>/dev/null | \
                jq -r '.[]' 2>/dev/null | \
                while IFS= read -r rule; do
                    if [ -n "$rule" ] && [ "$rule" != "null" ]; then
                        aws ec2 revoke-security-group-ingress --group-id "$sg_id" --ip-permissions "$rule" --region eu-west-3 2>/dev/null || true
                    fi
                done
                
                # Supprimer toutes les règles egress (sauf default)
                aws ec2 describe-security-groups --group-ids "$sg_id" --region eu-west-3 \
                    --query "SecurityGroups[0].IpPermissionsEgress" --output json 2>/dev/null | \
                jq -r '.[] | select(.IpRanges[0].CidrIp != "0.0.0.0/0" or .IpProtocol != "-1")' 2>/dev/null | \
                while IFS= read -r rule; do
                    if [ -n "$rule" ] && [ "$rule" != "null" ]; then
                        aws ec2 revoke-security-group-egress --group-id "$sg_id" --ip-permissions "$rule" --region eu-west-3 2>/dev/null || true
                    fi
                done
            fi
        done
        
        sleep 10
        
        # Deuxième passe : supprimer les SG
        for sg_id in $SG_IDS; do
            if [ -n "$sg_id" ] && [ "$sg_id" != "None" ]; then
                aws ec2 delete-security-group --group-id "$sg_id" --region eu-west-3 \
                && echo "✅ Security Group $sg_id supprimé" \
                || echo "⚠️ Échec suppression SG $sg_id"
            fi
        done
    fi
    
    # Subnets
    echo "🏗️ 4.4. Suppression Subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --region eu-west-3 \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query "Subnets[*].SubnetId" --output text 2>/dev/null || true)
    
    if [ -n "$SUBNET_IDS" ] && [ "$SUBNET_IDS" != "None" ]; then
        for subnet_id in $SUBNET_IDS; do
            if [ -n "$subnet_id" ] && [ "$subnet_id" != "None" ]; then
                aws ec2 delete-subnet --subnet-id "$subnet_id" --region eu-west-3 \
                && echo "✅ Subnet $subnet_id supprimé" \
                || echo "⚠️ Échec suppression subnet $subnet_id"
            fi
        done
    fi
    
    # VPC final
    echo "🏗️ 4.5. Suppression VPC..."
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region eu-west-3 \
    && echo "✅ VPC $VPC_ID supprimé" \
    || echo "⚠️ Échec suppression VPC"
fi

# ===========================================
# 5. DESTRUCTION SHARED
# ===========================================
echo ""
echo "📂 5. Destruction shared..."
if [ -d "envs/shared" ]; then
    cd envs/shared

    if terraform show >/dev/null 2>&1; then
        echo "🗑️ Destruction shared..."
        terraform destroy -auto-approve || echo "⚠️ Erreur destruction shared"
    fi
    
    rm -f terraform.tfstate* .terraform.lock.hcl errored.tfstate
    rm -rf .terraform/
    cd ../..
fi

# ===========================================
# 6. NETTOYAGE DB SUBNET GROUPS
# ===========================================
echo ""
echo "🗄️ 6. Nettoyage DB Subnet Groups..."
for subnet_group in "serverless-aurora-subnet-group" "classique-rds-subnet-group"; do
    aws rds delete-db-subnet-group --db-subnet-group-name "$subnet_group" --region eu-west-3 2>/dev/null \
    && echo "✅ $subnet_group supprimé" \
    || echo "ℹ️ $subnet_group non trouvé ou déjà supprimé"
done

# ===========================================
# 7. DESTRUCTION BOOTSTRAP
# ===========================================
echo ""
echo "📂 7. Destruction bootstrap..."
if [ -d "envs/bootstrap" ]; then
    cd envs/bootstrap
    
    # Migration backend local
    cat > backend_local.tf << 'EOF'
terraform {
  # Backend local pour destruction
}
EOF
    
    terraform init -migrate-state -force-copy >/dev/null 2>&1 || true
    terraform destroy -auto-approve || echo "⚠️ Erreur bootstrap"
    
    rm -f backend_local.tf terraform.tfstate* .terraform.lock.hcl errored.tfstate
    rm -rf .terraform/
    cd ../..
fi

# ===========================================
# 8. NETTOYAGE FINAL
# ===========================================
echo ""
echo "🧹 8. Nettoyage final..."

# Bucket S3
BUCKET_NAME="my-s3-shared-backend-s-vs-c-2025"
if aws s3 ls "s3://$BUCKET_NAME" >/dev/null 2>&1; then
    aws s3 rm "s3://$BUCKET_NAME" --recursive --quiet 2>/dev/null || true
    aws s3 rb "s3://$BUCKET_NAME" --force \
    && echo "✅ Bucket S3 supprimé" \
    || echo "⚠️ Échec suppression bucket"
fi

# DynamoDB
aws dynamodb delete-table --table-name tfstate-locks --region eu-west-3 >/dev/null 2>&1 \
&& echo "✅ Table DynamoDB supprimée" \
|| echo "ℹ️ Table DynamoDB non trouvée"

# KMS
for alias in "alias/tfstate-backend-v2" "alias/cloudtrail-logs"; do
    if aws kms describe-key --key-id "$alias" --region eu-west-3 >/dev/null 2>&1; then
        KEY_ID=$(aws kms describe-key --key-id "$alias" --region eu-west-3 \
            --query 'KeyMetadata.KeyId' --output text 2>/dev/null || true)
        
        aws kms delete-alias --alias-name "$alias" --region eu-west-3 2>/dev/null || true
        
        if [ -n "$KEY_ID" ] && [ "$KEY_ID" != "None" ]; then
            aws kms schedule-key-deletion --key-id "$KEY_ID" --region eu-west-3 \
                --pending-window-in-days 7 >/dev/null 2>&1 || true
        fi
        echo "✅ KMS $alias planifié pour suppression"
    fi
done

# Nettoyage local
find . -name "terraform.tfstate*" -delete 2>/dev/null || true
find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
find . -name "errored.tfstate" -delete 2>/dev/null || true

echo ""
echo "✅ DESTRUCTION INTELLIGENTE TERMINÉE !"
echo ""
echo "📊 Ordre de destruction optimisé :"
echo "   1. Lambda + API Gateway (libération ENI)"
echo "   2. VPC Endpoints (déblocage réseau)"
echo "   3. Aurora Serverless (base de données)"
echo "   4. Auto Scaling Group (instances EC2)"
echo "   5. Security Groups (dans le bon ordre)"
echo "   6. Infrastructure réseau (NAT, IGW, Subnets)"
echo "   7. Ressources partagées et storage"
echo ""
echo "💡 Si des ressources persistent, relancez le script."