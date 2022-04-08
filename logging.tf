resource "kubernetes_manifest" "namespace_openshift_elasticsearch_operator" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "annotations" = {
        "openshift.io/node-selector" = ""
      }
      "labels" = {
        "openshift.io/cluster-monitoring" = "true"
      }
      "name" = "openshift-operators-redhat"
    }
  }

  depends_on = [ibm_container_worker_pool.logmon]
}

resource "kubernetes_manifest" "namespace_openshift_logging_operator" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "annotations" = {
        "openshift.io/node-selector" = ""
      }
      "labels" = {
        "openshift.io/cluster-monitoring" = "true"
      }
      "name" = "openshift-logging"
    }
  }

  depends_on = [kubernetes_manifest.namespace_openshift_elasticsearch_operator]
}

resource "kubernetes_manifest" "operatorgroup_openshift_elasticsearch_operator" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind"       = "OperatorGroup"
    "metadata" = {
      "name"      = "openshift-operators-redhat"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {}
  }

  depends_on = [kubernetes_manifest.namespace_openshift_logging_operator]
}

resource "kubernetes_manifest" "subscription_openshift_elasticsearch_operator" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind"       = "Subscription"
    "metadata" = {
      "name"      = "elasticsearch-operator"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {
      "channel"             = "stable-5.2"
      "name"                = "elasticsearch-operator"
      "source"              = "redhat-operators"
      "sourceNamespace"     = "openshift-marketplace"
      "installPlanApproval" = "Automatic"
    }
  }

  depends_on = [kubernetes_manifest.operatorgroup_openshift_elasticsearch_operator]
}

resource "kubernetes_manifest" "operatorgroup_openshift_logging_operator" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind"       = "OperatorGroup"
    "metadata" = {
      "name"      = "cluster-logging"
      "namespace" = "openshift-logging"
    }
    "spec" = {
      "targetNamespaces" = [
        "openshift-logging",
      ]
    }
  }

  depends_on = [kubernetes_manifest.subscription_openshift_elasticsearch_operator]
}

resource "kubernetes_manifest" "subscription_openshift_logging_cluster_logging" {
  count = var.install_logging == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind"       = "Subscription"
    "metadata" = {
      "name"      = "cluster-logging"
      "namespace" = "openshift-logging"
    }
    "spec" = {
      "channel"             = "stable-5.2"
      "name"                = "cluster-logging"
      "source"              = "redhat-operators"
      "sourceNamespace"     = "openshift-marketplace"
      "installPlanApproval" = "Automatic"
    }
  }

  depends_on = [kubernetes_manifest.operatorgroup_openshift_logging_operator]
}

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