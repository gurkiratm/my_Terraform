terraform {
  
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "1.15.0"
    }
  }

  # backend "s3" {
  #   bucket         = "my-terraform-state-bucket-vpshere"
  #   key            = "dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }

}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
  # api_timeout          = 10
}