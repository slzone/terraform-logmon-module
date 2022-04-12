resource "ibm_container_worker_pool" "logmon" {
  count = ((var.use_default_worker_pool == false) && (var.install_logging || var.install_monitoring)) == true ? 1 : 0

  worker_pool_name = "logmon-worker-pool"
  machine_type     = "mx2.4x32" # 4 vCPU, 32 GB Memory
  cluster          = var.cluster_name
  size_per_zone    = 1
  hardware         = "shared"
  disk_encryption  = "true"
  entitlement      = "cloud_pak"

  # Ensure only the logging stack runs on this worker pool
  taints {
    key    = "logging-monitoring"
    value  = "node"
    effect = "NoExecute"
  }
}