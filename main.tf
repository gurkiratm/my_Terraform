provider "aws" { #block configures options that apply to all resources managed by your provider, such as the region to create them in. 
  #The label of the provider block corresponds to the name of the provider in the required_providers list in your terraform block.
  region = "ap-south-1"
}
data "aws_ami" "ubuntu" {
  most_recent = true #argument ensures that the data source returns the most recent AMI that matches the filter criteria.

  filter { #filter block defines criteria to narrow down the search for the AMI.
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] #argument specifies the pattern to match AMI names.
  }

  owners = ["099720109477"] # Canonical #argument restricts the search to AMIs owned by Canonical, the publisher of Ubuntu.
}

resource "aws_instance" "app_server" { # resource type and resource name.
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "learn-terraform"
  }
}