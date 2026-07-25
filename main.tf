module "vpc" {
    source = "git::https://github.com/mangeshchauhan/AWS-Modules.git//vpc"
    vpc_cidr = var.vpc_cidr
    subnets  = var.subnets

}

