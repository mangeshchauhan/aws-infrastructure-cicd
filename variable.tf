variable "vpc_cidr" {
    type = string
}
variable "subnets" {
    type = map(object({
        cidr_block        = string
        availability_zone = string
        public            = bool
    }))
}
variable "instances" {
  description = "Map of EC2 instances"
  type = map(object({
    ami           = string
    instance_type = string
    subnet_key    = string
  }))
}