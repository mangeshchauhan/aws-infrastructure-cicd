 vpc_cidr = "10.10.0.0/16"
  subnets = {
    public-subnet-1 = {
      cidr_block = "10.10.1.0/24"
      availability_zone = "us-east-1a"
      public            = true
    }
    private-subnet-1 = {
      cidr_block = "10.10.2.0/24"
      availability_zone = "us-east-1a"
      public            = false
    }
     public-subnet-2 = {
      cidr_block = "10.10.3.0/24"
      availability_zone = "us-east-1b"
      public            = true
    }
     private-subnet-2 = {
      cidr_block = "10.10.4.0/24"
      availability_zone = "us-east-1b"
      public            = false
    }
  }
instances = {
  app1 = {
    ami           = "ami-0abc12345def67890"
    instance_type = "t3.medium"
    subnet_key    = "public-subnet-1"
  }
  app2 = {
    ami           = "ami-0abc12345def67890"
    instance_type = "t2.small"
    subnet_key    = "private-subnet-1"
  }
}


