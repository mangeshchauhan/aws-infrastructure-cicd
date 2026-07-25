provider "aws" {
  region = "us-east-1"
}
backend "s3" {
  bucket = "dev-env-terraform-12345"
  key    = "terraform.tfstate"
  region = "us-east-1"
}