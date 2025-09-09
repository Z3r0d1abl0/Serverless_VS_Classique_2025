# Data pour le choix de l'AMI qui sera utilisée pour le scaling group
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"] # AMI officielles Amazon

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # Amazon Linux 2023
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Création du launch template
resource "aws_launch_template" "this" {
  name_prefix   = var.name
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name != "" ? [1] : []
    content {
      name = var.iam_instance_profile_name
    }
  }

  key_name = var.key_name

  vpc_security_group_ids = var.security_group_ids

  user_data = var.user_data != "" ? base64encode(var.user_data) : null

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }
}

# Création de l'Auto Scaling Group
resource "aws_autoscaling_group" "this" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  target_group_arns = var.target_group_arns

  # --- AJOUTS pour que le dashboard voie les métriques ASG ---
  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
  # -----------------------------------------------------------

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
