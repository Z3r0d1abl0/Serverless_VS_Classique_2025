resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = var.aliases

  origin {
    domain_name = var.s3_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = var.cloudfront_oai_path
    }
  }

  origin {
    domain_name = var.api_gateway_domain_name
    origin_id   = "APIGWOrigin"
    origin_path = var.api_gateway_path

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    # Politique de cache gérée par AWS
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # Managed-CachingOptimized
    compress        = true
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "APIGWOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    # Désactiver le cache pour l'API
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # Managed-CachingDisabled
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # Managed-CORS-S3Origin

    compress = true
  }

  price_class = var.price_class

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Web ACL conditionnel
  web_acl_id = var.web_acl_id != null && var.web_acl_id != "" ? var.web_acl_id : null

  tags = var.tags
}