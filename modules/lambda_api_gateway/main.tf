# Lambda - Fonction reliée à Aurora Serverless V2
resource "aws_lambda_function" "main" {
  function_name = "${var.env_prefix}-lambda-aurora-v2"
  filename      = var.lambda_zip_path
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = var.lambda_role_arn
  timeout       = 15

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      DB_HOST        = var.aurora_endpoint
      DB_USER        = var.db_username
      DB_PASSWORD    = var.db_password
      DB_NAME        = var.db_name
      DB_PORT        = var.db_port
      DB_ENGINE_MODE = "serverless-v2"
    }
  }

  tags = merge(var.tags, {
    Name     = "${var.env_prefix}-lambda-aurora-v2"
    Database = "aurora-serverless-v2"
  })
}

# API Gateway HTTP v2
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.env_prefix}-lambda-api-v2"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    allow_methods     = ["GET", "POST", "OPTIONS", "PUT", "DELETE"]
    allow_origins     = ["https://serverless.projectdemocloud.com"]
    expose_headers    = ["date", "keep-alive", "x-amz-request-id"]
    max_age          = 86400
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.main.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route principale pour /api/*
resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "ANY /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Route explicite pour OPTIONS
resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "OPTIONS /api/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Lambda - Permission API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}