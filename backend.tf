terraform {
  backend "s3" {
    bucket       = "terraform-state-bucket-00100126"
    key          = "lesson-5/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
    encrypt      = true
  }
}