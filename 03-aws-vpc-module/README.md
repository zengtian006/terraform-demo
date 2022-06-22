# Evolution #3 

![day3](../img/arch-day3.png)

## Step 1: Provision Day 2 Architecture (if you deleted)

`terraform apply --auto-approve`

## Step 2: Create custom VPC

### a. Use Terraform resources - without Terraform Module

We need to add `vpc*1 + subnet*2 + igw*1 + rt*1 + rta*2` = 7 resource blocks

```terraform
# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = "true"
}

resource "aws_subnet" "subnet1" {
  cidr_block              = "10.1.0.0/24"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "subnet2" {
  cidr_block              = "10.1.1.0/24"
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1b"
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rtb.id
}
resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rtb.id
}
```

### b: With Terraform VPC module (recommended)

Only need one VPC module

```terraform

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = []
  public_subnets  = ["10.1.0.0/24", "10.1.1.0/24"]

}
```



