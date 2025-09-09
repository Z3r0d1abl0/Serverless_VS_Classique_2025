
# Création du bucket s3_website

resource "aws_s3_bucket" "website" {
  bucket        = var.bucket_name
  force_destroy = true
  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

# Versioning pour le bucket S3
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = "Enabled"
  }
}



# Configuration du site web (gardée pour compatibilité)

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_object" "index_html" {
  bucket = aws_s3_bucket.website.id
  key    = "index.html"
  content = templatefile("${path.module}/index.html", {
    classique_url      = var.classique_url
    serverless_api_url = var.serverless_api_url
    alb_name           = var.alb_name
    lambda_name        = var.lambda_name
    aurora_cluster     = var.aurora_cluster
  })
  content_type = "text/html"
}

resource "aws_s3_object" "error_html" {
  bucket       = aws_s3_bucket.website.id
  key          = "error.html"
  source       = "${path.module}/error.html"
  content_type = "text/html"
}

# S3 privé pour cloudfront , accès par OAI
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  # Bloquer TOUT accès public pour forcer le passage par CloudFront
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Accès par cloudfront en OAI exclusivement

resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.cloudfront_access.json

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# Policy explicite que par OAI pour cloudfront 

data "aws_iam_policy_document" "cloudfront_access" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.cloudfront_oai_arn] # passé par main serverless (module cloudfront)
    }

    effect = "Allow"
  }
}

# Passage CORS par api 
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  depends_on = [ aws_s3_bucket.website ]
}