// Create infrastructure for operational logging and monitoring

// Create a dedicated worker pool for logging (and eventually monitoring)


resource "ibm_container_vpc_worker_pool" "pool" {
  cluster           = var.cluster_name
  worker_pool_name  = var.worker_pool_name
  flavor            = var.flavor
  vpc_id            = var.virtual_private_cloud
  worker_count      = var.worker_nodes_per_zone
  resource_group_id = var.resource_group_id
  labels            = (var.labels != null ? var.labels : null)
  entitlement       = (var.entitlement != null ? var.entitlement : null)

  dynamic zones {
    for_each = (var.worker_zones != null ? var.worker_zones : {})
    content {
      name      = zones.key
      subnet_id = zones.value.subnet_id
    }
  }

  dynamic taints {
    for_each = (var.taints != null ? var.taints : [])
    content {
      key    = taints.value.key
      value  = taints.value.value
      effect = taints.value.effect
    }
  }

  timeouts {
    create = (var.create_timeout != null ? var.create_timeout : null)
    delete = (var.delete_timeout != null ? var.delete_timeout : null)
  }
}

data "ibm_container_cluster_config" "cluster" {
  resource_group_id = var.resource_group_id
  cluster_name_id   = var.cluster_name
  admin             = true
  config_dir        = var.schematics == true ? "/tmp/.schematics" : "."
}
