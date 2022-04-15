
variable "ibmcloud_api_key" {
  type      = string
  sensitive = true
}

variable "region" {
  description = "Region to provision the Openshift cluster. List all available regions with: ibmcloud regions"
  type        = string
}

variable "resource_group" {
  description = "Name of resource group"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "schematics" {
  type        = bool
  default     = true
  description = "Set to false if you are not running this template in schematics"
}

variable "install_logging" {
  type        = bool
  default     = false
  description = "Set to true to install logging"
}

variable "install_monitoring" {
  type        = bool
  default     = false
  description = "Set to true to install monitoring"
}