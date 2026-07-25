terraform {
  backend "s3" {
  bucket = "dev-env-terraform-12345"
  key    = "terraform.tfstate"
  region = "us-east-1"
}
}



module "vpc" {
    source = "git::https://github.com/mangeshchauhan/AWS-Modules.git//vpc"
    vpc_cidr = var.vpc_cidr
    subnets  = var.subnets

}

