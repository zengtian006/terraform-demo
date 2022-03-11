
# VARIABLES
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "key_name" {}


# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# RESOURCES
#This uses the default VPC.  It WILL NOT delete it on destroy.
resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "nginx-sg" {
  name        = "nginx_demo"
  description = "Allow ports for nginx demo"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = "ami-005e54dee72cc1d00"
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  tags = {
    Name = "web-server"
  }
  user_data = <<-EOF
               #! bin/bash
               sudo yum install nginx -y
               sudo service nginx start
               EOF
}

# OUTPUT
output "aws_instance_public_dns" {
  value = aws_instance.nginx.public_dns
}