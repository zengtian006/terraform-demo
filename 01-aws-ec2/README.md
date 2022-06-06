# Evolution #1 

![day1](../img/arch-day1.png)

## Step 1: Pre-requsite

### Install Terrafrom

https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started

### Create AWS Free Account

https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/


## Step 2: Build the infrastructure

### Add AWS provider module and provider congifuration

Reference: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

```terraform
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
  region = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```

