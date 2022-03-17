provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

provider "kubernetes" {
   version = ">=1.8.1"
   host                   = data.ibm_container_cluster_config.cluster.host
   client_certificate     = data.ibm_container_cluster_config.cluster.admin_certificate
   client_key             = data.ibm_container_cluster_config.cluster.admin_key
   cluster_ca_certificate = data.ibm_container_cluster_config.cluster.ca_certificate
}

data "ibm_container_cluster_config" "cluster" {
  resource_group_id = var.resource_group_id
  cluster_name_id   = var.cluster_name
  admin             = true
  config_dir        = var.schematics == true ? "/tmp/.schematics" : "."
}
