variable "vpc_id" {
  type    = string
  default = "vpc-test"
}

variable "public_subnet_ids" {
  type    = list(string)
  default = ["subnet-test1", "subnet-test2"]
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_id" {
  type    = string
  default = ""
}