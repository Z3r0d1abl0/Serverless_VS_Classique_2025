terraform {
  backend "s3" {
    bucket         = "my-s3-shared-backend-s-vs-c-2025" # nom du bucket créé par bootstrap
    key            = "shared/terraform.tfstate"         # chemin du fichier state dans le bucket
    region         = "eu-west-3"                        # région du bucket
    dynamodb_table = "tfstate-locks"                    # table DynamoDB de lock créée par bootstrap
    encrypt        = true                               # active le chiffrement SSE
    kms_key_id     = "alias/tfstate-backend-v2"         # clé KMS créée par bootstrap
  }
}
