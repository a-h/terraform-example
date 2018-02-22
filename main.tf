terraform {
  backend "s3" {
    bucket = "ah-terraform-state"
    region = "eu-west-2"
  }
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.5"
}
