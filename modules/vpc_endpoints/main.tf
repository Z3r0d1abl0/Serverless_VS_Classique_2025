
#Vpc endpoint pour S3_website

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-s3-endpoint"
  })
}

#Interface endpoint pour secrets_manager (pour communication avec les db)

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpce_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-secretsmanager-endpoint"
  })
}

#Interface endpoint pour les clés KMS (S3_logs)

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpce_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-kms-endpoint"
  })
}

#Interface endpoint pour cloudwatch_logs ()

resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.vpce_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-cloudwatchlogs-endpoint"
  })
}
