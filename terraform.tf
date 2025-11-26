terraform {                     #The terraform block configures Terraform itself
  required_providers {          #lets you set version constraints on the providers your configuration uses.
    aws = {                     #This name is just a label for provider configuration. #it must match the name used in the provider block.
      source  = "hashicorp/aws" #argument specifies a hostname (optional), namespace, and provider name. #shortened form of registry.terraform.io/hashicorp/aws, the address of the provider in the Terraform Registry.
      version = "~> 5.92"       #argument sets a version constraint for your AWS provider. #defaults to the most recent version of the provider
    }
  }

  required_version = ">= 1.14.0" #the required version of Terraform, means your configuration supports any version of Terraform greater than or equal to 1.14.0

}