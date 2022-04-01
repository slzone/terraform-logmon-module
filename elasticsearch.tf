resource "kubernetes_manifest" "namespace_openshift_operators_redhat" {
  #depends_on = [ibm_container_vpc_worker_pool.pool]

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
  depends_on = [kubernetes_manifest.namespace_openshift_logging]

  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind"       = "OperatorGroup"
    "metadata" = {
      "name"      = "openshift-operators-redhat"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {}
  }
}

resource "kubernetes_manifest" "subscription_openshift_operators_redhat_elasticsearch_operator" {
  depends_on = [kubernetes_manifest.operatorgroup_openshift_operators_redhat_openshift_operators_redhat]

  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind"       = "Subscription"
    "metadata" = {
      "name"      = "elasticsearch-operator"
      "namespace" = "openshift-operators-redhat"
    }
    "spec" = {
      "channel"         = "stable-5.2"
      "name"            = "elasticsearch-operator"
      "source"          = "redhat-operators"
      "sourceNamespace" = "openshift-marketplace"
    }
  }
}

