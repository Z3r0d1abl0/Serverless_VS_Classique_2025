
# Création du subnet group pour rds 

resource "aws_db_subnet_group" "this" {
  name       = "${var.env_prefix}-rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.env_prefix}-rds-subnet-group"
    Env  = var.env_prefix
  }
}

# Création des db rds mysql v8 (multi AZ true)

resource "aws_db_instance" "this" {
  identifier                      = "${var.env_prefix}-rds"
  engine                          = "mysql"
  engine_version                  = var.engine_version
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage
  db_name                         = var.db_name
  username                        = var.db_username
  password                        = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.vpc_security_group_ids
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  multi_az                        = true
  publicly_accessible             = false
  skip_final_snapshot             = true
  deletion_protection             = false
  backup_retention_period         = 7
  storage_encrypted               = true

  tags = {
    Name = "${var.env_prefix}-rds"
    Env  = var.env_prefix
  }
}
