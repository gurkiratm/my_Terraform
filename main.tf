provider "aws" { #block configures options that apply to all resources managed by your provider, such as the region to create them in. 
  #The label of the provider block corresponds to the name of the provider in the required_providers list in your terraform block.
  region = "ap-south-1"
}
data "aws_ami" "ubuntu" { #Data source type and data source name.
  most_recent = true      #argument ensures that the data source returns the most recent AMI that matches the filter criteria.

  filter { #filter block defines criteria to narrow down the search for the AMI.
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] #argument specifies the pattern to match AMI names.
  }

  owners = ["099720109477"] # Canonical #argument restricts the search to AMIs owned by Canonical, the publisher of Ubuntu.
}

resource "aws_instance" "app_server" { # resource type and resource name.
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]
  tags = {
    Name = var.instance_name
  }
}

module "vpc" {

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = "example-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_dns_hostnames = true
}
