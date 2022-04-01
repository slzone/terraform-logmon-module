resource "kubernetes_manifest" "namespace_openshift_logging" {
  depends_on = [kubernetes_manifest.subscription_openshift_operators_redhat_elasticsearch_operator]

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "annotations" = {
        "openshift.io/node-selector" = ""
      }
      "labels" = {
        "openshift.io/cluster-logging" = "true"
        "openshift.io/cluster-monitoring" = "true"
      }
      "name" = "openshift-logging"
    }
  }
}

resource "kubernetes_manifest" "operatorgroup_openshift_logging_cluster_logging" {
  depends_on = [kubernetes_manifest.namespace_openshift_logging]

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
}
resource "kubernetes_manifest" "subscription_openshift_logging_cluster_logging" {
  depends_on = [kubernetes_manifest.operatorgroup_openshift_logging_cluster_logging]

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
}

