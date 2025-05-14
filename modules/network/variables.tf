variable "vpc_id" {
  description = "The VPC ID to use."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs."
  type        = list(string)
}


variable "private_subnet_ids" {
  type    = list(string)
  default = ["private-subnet-1", "private-subnet-2"]
}