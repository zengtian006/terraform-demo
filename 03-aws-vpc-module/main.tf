
# VARIABLES
variable "aws_access_key" {}
variable "aws_secret_key" {}

# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "webapp_module" {
  source   = "./webapp_module"
  web_name = "tim-web"
}