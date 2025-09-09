# Aurora Serverless subnet group
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.env_prefix}-aurora-subnet-group"
  subnet_ids = var.subnet_ids
  tags = merge(var.tags, {
    Name = "${var.env_prefix}-aurora-subnet-group"
  })
}

# Aurora Serverless V2 cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.env_prefix}-aurora"
  engine                         = "aurora-mysql"
  engine_mode                    = "provisioned"
  engine_version                 = var.engine_version
  master_username                = var.db_username
  master_password                = var.db_password
  database_name                  = var.db_name
  db_subnet_group_name           = aws_db_subnet_group.aurora.name
  vpc_security_group_ids         = var.security_group_ids
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  storage_encrypted              = true
  backup_retention_period        = 7
  skip_final_snapshot           = true

  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-aurora"
    Type = "serverless-v2"
  })
}

# Instances Aurora Multi-AZ
resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = 2
  identifier         = "${var.env_prefix}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine            = aws_rds_cluster.aurora.engine
  engine_version    = aws_rds_cluster.aurora.engine_version
  availability_zone  = count.index == 0 ? "eu-west-3a" : "eu-west-3b"

  performance_insights_enabled = false
  monitoring_interval         = 0

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-aurora-instance-${count.index + 1}"
    Role = count.index == 0 ? "writer" : "reader"
  })
}