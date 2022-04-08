resource "kubernetes_manifest" "namespace_openshift_operators_redhat" {
  #depends_on = [ibm_container_vpc_worker_pool.pool]
  count = var.install_monitoring == true ? 1 : 0

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
}

resource "kubernetes_manifest" "operatorgroup_openshift_operators_redhat_openshift_operators_redhat" {
  count = var.install_monitoring == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind"       = "OperatorGroup"
    "metadata" = {
      "name"      = "openshift-operators-redhat"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {}
  }

  depends_on = [kubernetes_manifest.namespace_openshift_operators_redhat]
}

resource "kubernetes_manifest" "subscription_openshift_operators_redhat_elasticsearch_operator" {
  count = var.install_monitoring == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind"       = "Subscription"
    "metadata" = {
      "name"      = "elasticsearch-operator"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {
      "channel"             = "stable-5.2"
      "installPlanApproval" = "Automatic"
      "name"                = "elasticsearch-operator"
      "source"              = "redhat-operators"
      "sourceNamespace"     = "openshift-marketplace"
    }
  }

  depends_on = [kubernetes_manifest.operatorgroup_openshift_operators_redhat_openshift_operators_redhat]
}

