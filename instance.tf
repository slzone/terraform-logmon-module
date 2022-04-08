resource "kubernetes_manifest" "clusterlogging_openshift_logging_instance" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "logging.openshift.io/v1"
    "kind"       = "ClusterLogging"
    "metadata" = {
      "name"      = "instance"
      "namespace" = "openshift-logging"
    }
    "spec" = {
      "collection" = {
        "logs" = {
          "fluentd" = {}
          "type"    = "fluentd"
        }
      }
      "curation" = {
        "curator" = {
          "schedule" = "30 3 * * *"
        }
        "type" = "curator"
      }
      "logStore" = {
        "elasticsearch" = {
          "nodeCount" = 3
          "proxy" = {
            "resources" = {
              "limits" = {
                "memory" = "256Mi"
              }
              "requests" = {
                "memory" = "256Mi"
              }
            }
          }
          "redundancyPolicy" = "SingleRedundancy"
          "resources" = {
            "limits" = {
              "memory" = "16Gi"
            }
            "requests" = {
              "memory" = "16Gi"
            }
          }
          "storage" = {
            "size"             = "200G"
            "storageClassName" = "ibmc-vpc-block-general-purpose"
          }
        }
        "retentionPolicy" = {
          "application" = {
            "maxAge" = "1d"
          }
          "audit" = {
            "maxAge" = "7d"
          }
          "infra" = {
            "maxAge" = "7d"
          }
        }
        "type" = "elasticsearch"
      }
      "managementState" = "Managed"
      "visualization" = {
        "kibana" = {
          "replicas" = 1
        }
        "type" = "kibana"
      }
    }
  }

  depends_on = [kubernetes_manifest.subscription_openshift_logging_cluster_logging]
}
