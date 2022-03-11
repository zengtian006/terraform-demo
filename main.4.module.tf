
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

# DATA
data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# RESOURCES
#This uses the default VPC.  It WILL NOT delete it on destroy.
# resource "aws_default_vpc" "default" {

# }

# NETWORKING #
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = []
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name   = "nginx_elb_sg"
  vpc_id = module.vpc.vpc_id

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nginx-sg" {
  name        = "nginx_demo"
  description = "Allow ports for nginx demo"
  vpc_id      = module.vpc.vpc_id

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

# LOAD BALANCER #
resource "aws_elb" "web" {
  name = "nginx-elb"

  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.elb-sg.id]
  instances       = [aws_instance.nginx1.id, aws_instance.nginx2.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_instance" "nginx1" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  subnet_id              = module.vpc.public_subnets[0]
  tags = {
    Name = "nginx1"
  }
  user_data = <<-EOF
               #! bin/bash
               sudo yum install nginx -y
               sudo service nginx start
               sudo rm /usr/share/nginx/html/index.html
               echo '<html><head><title>Blue Team Server</title></head><body style="background-color:#1F778D"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Blue Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
               EOF
}

resource "aws_instance" "nginx2" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  subnet_id              = module.vpc.public_subnets[1]
  tags = {
    Name = "nginx2"
  }
  user_data = <<-EOF
               #! bin/bash
               sudo yum install nginx -y
               sudo service nginx start
               sudo rm /usr/share/nginx/html/index.html
               echo '<html><head><title>Green Team Server</title></head><body style="background-color:#77A032"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Green Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
               EOF
}
# OUTPUT

output "aws_instance_public_dns" {
  value = aws_elb.web.dns_name
}