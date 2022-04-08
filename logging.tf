resource "kubernetes_manifest" "namespace_openshift_logging" {
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

  depends_on = [kubernetes_manifest.namespace_openshift_operators_redhat]
}

resource "kubernetes_manifest" "operatorgroup_openshift_logging_cluster_logging" {
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

  depends_on = [kubernetes_manifest.namespace_openshift_logging]
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
      "channel"         = "stable-5.2"
      "name"            = "cluster-logging"
      "source"          = "redhat-operators"
      "sourceNamespace" = "openshift-marketplace"
    }
  }

  depends_on = [kubernetes_manifest.operatorgroup_openshift_logging_cluster_logging]
}
