
##############################################################################
# Terraform Providers
##############################################################################
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.36.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 1.8.1"
    }
  }
  required_version = ">= 1.0"
}