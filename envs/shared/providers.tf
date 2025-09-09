provider "aws" {
  region = "eu-west-3"
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1" # Région pour CloudFront/ACM
}