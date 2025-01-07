# Backend configuration require a AWS storage bucket.
terraform {
  backend "s3" {
    bucket = "tech-challenger-2-backup-tf"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
  }
}