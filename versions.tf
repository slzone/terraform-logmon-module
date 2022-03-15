
##############################################################################
# Terraform Providers
##############################################################################
terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.36.0"
    }
  }
  required_version = ">= 1.0"
}

provider "kubernetes" {
   version = ">=1.8.1"
   host                   = data.ibm_container_cluster_config.cluster.host
   client_certificate     = data.ibm_container_cluster_config.cluster.admin_certificate
   client_key             = data.ibm_container_cluster_config.cluster.admin_key
   cluster_ca_certificate = data.ibm_container_cluster_config.cluster.ca_certificate
}