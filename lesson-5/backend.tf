terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-00100126"
    key            = "lesson-5/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}