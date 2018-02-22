variable "region" {
  description = "The AWS region to create resources in."
  default     = "eu-west-2"
}

variable "environment" {
  description = "The deployment environment."
}

variable "application" {
  description = "The name of the Application."
}

variable "availability_zones" {
  description = "The availability zones"
  type        = "list"
  default     = ["eu-west-2a", "eu-west-2b"]
}

variable "public_subnet_ranges" {
  type    = "list"
  default = ["10.0.50.0/24", "10.0.51.0/24"]
}

variable "private_subnet_ranges" {
  type    = "list"
  default = ["10.0.40.0/24", "10.0.41.0/24"]
}

variable "ecs_amis" {
  default = {
    eu-west-2 = "ami-67cbd003"
  }
}

variable "ecs_instance_type" {
  default = "t2.micro"
}

variable "aurora_instance_type" {
  default = "db.t2.small"
}

variable "key_name" {
  description = "The aws ssh key name."
}

variable "master_username" {}

variable "master_password" {}

variable "master_database" {}

variable "wordpress_image_tag" {
  default = "latest"
}