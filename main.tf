provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

data "ibm_container_cluster_config" "cluster" {
  cluster_name_id   = var.cluster_name
  resource_group_id = data.ibm_resource_group.group.id
  admin             = true
  config_dir        = var.schematics == true ? "/tmp/.schematics" : "."
  download          = true
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster.host
  client_certificate     = data.ibm_container_cluster_config.cluster.admin_certificate
  client_key             = data.ibm_container_cluster_config.cluster.admin_key
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster.ca_certificate
}
