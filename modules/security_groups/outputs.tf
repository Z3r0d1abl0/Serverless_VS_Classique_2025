output "aurora_sg_id" {
  value = aws_security_group.aurora.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}

output "sc_sg_id" {
  value = aws_security_group.sc.id

}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "vpce_sg_id" {
  value = aws_security_group.vpce.id
}