########################################
# ARCHITECTURE CLASSIQUE
########################################

# SG pour RDS MySQL (autorise uniquement EC2 du scaling group)
resource "aws_security_group" "rds_sg" {
  name        = "${var.env_prefix}-rds-sg"
  description = "SG for RDS MySQL - only from EC2 web"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from Scaling Group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.sc.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-rds-sg"
  })
}

# SG pour l'ALB
resource "aws_security_group" "alb" {
  name        = "${var.env_prefix}-alb-sg"
  description = "Security Group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# SG du scaling group (EC2)
resource "aws_security_group" "sc" {
  name        = "${var.env_prefix}-sc-sg"
  description = "Security Group for EC2 instances in ASG"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Allow HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

########################################
# ARCHITECTURE SERVERLESS
########################################

# SG Lambda (sortie vers Aurora + VPC Endpoints)
resource "aws_security_group" "lambda_sg" {
  name        = "${var.env_prefix}-lambda-sg"
  description = "SG pour Lambda serverless"
  vpc_id      = var.vpc_id

  egress {
    description = "MySQL vers Aurora"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "HTTPS vers VPC Endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-lambda-sg"
  })
}

# SG Aurora MySQL (autorise uniquement Lambda)
resource "aws_security_group" "aurora" {
  name        = "${var.env_prefix}-aurora-sg"
  description = "SG pour Aurora MySQL Serverless"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL depuis Lambda"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-aurora-sg"
  })
}

# SG pour les VPC Endpoints privés (SecretsManager, KMS, CloudWatch Logs)
resource "aws_security_group" "vpce" {
  name        = "${var.env_prefix}-vpce-sg"
  description = "SG pour les VPC Endpoints prives (SecretsManager, KMS, CloudWatch Logs)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTPS depuis Lambda"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.env_prefix}-vpce-sg"
  })
}
