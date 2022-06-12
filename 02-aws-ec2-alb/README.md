# Evolution #2 

![day1](../img/arch-day2.png)

## Step 1: Provision Day 1 Architecture (if you deleted)

## Step 2: Replace hardcoded values with <ins>Variable</ins>

### a. Add Variables in `main.tf`

### b. Create `terraform.tfvars` under root folder

### c. Reference the Variable in `aws` Provider

## Step 3: Fetch AMI ID using <ins>Data Source</ins>

### a. Add `aws_ami` Data block

```terraform
data "aws_ami" "aws-linux" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*"]
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
```

For more details, please visit https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami

### b. Reference Data souece in EC2 block

```terraform
resource "aws_instance" "blue" {
  ami                    = data.aws_ami.aws-linux.id
  ...
}
```

## Step 4: Migrate to HA architecture using <ins>Resource</ins>

### a. Add subnet * 2

```terraform
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.31.128.0/24" 
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_default_vpc.default.id
  cidr_block = "172.31.255.0/24" 
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}
```

### b. Add EC2 instacne * 2

```terraform
resource "aws_instance" "blue" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  subnet_id = aws_subnet.subnet1.id
  tags = {
    Name = "Blue team"
  }
  user_data = <<-EOF
               #! bin/bash
               sudo amazon-linux-extras install epel -y
               sudo yum update
               sudo yum install nginx -y
               sudo service nginx start
               sudo rm /usr/share/nginx/html/index.html
               echo '<html><head><title>Blue Team Server</title></head><body style="background-color:#1F778D"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Blue Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
               EOF
}

resource "aws_instance" "green" {
  ami                    = data.aws_ami.aws-linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
  subnet_id = aws_subnet.subnet2.id
  tags = {
    Name = "Green team"
  }
  user_data = <<-EOF
               #! bin/bash
               sudo amazon-linux-extras install epel -y
               sudo yum update
               sudo yum install nginx -y
               sudo service nginx start
               sudo rm /usr/share/nginx/html/index.html
               echo '<html><head><title>Green Team Server</title></head><body style="background-color:#77A032"><p style="text-align: center;"><span style="color:#FFFFFF;"><span style="font-size:28px;">Green Team</span></span></p></body></html>' | sudo tee /usr/share/nginx/html/index.html
               EOF
}
```

### c. Add ELB

```terraform
#ELB
# Create a new load balancer
resource "aws_elb" "web" {
  name               = "nginx-elb"

  subnets = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups = [aws_security_group.nginx-sg.id]
  instances = [aws_instance.blue.id, aws_instance.green.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}
```

### d. Remove the old EC2

```terraform
resource "aws_instance" "nginx" {
  ami                    = "ami-06eecef118bbf9259"
  instance_type          = "t2.micro"
  ......
}
```