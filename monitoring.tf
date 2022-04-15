resource "kubernetes_manifest" "namespace_my_grafana_operator" {
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
      "name" = "my-grafana-operator"
    }
  }
}

resource "kubernetes_manifest" "configmap_openshift_monitoring_cluster_monitoring_config" {
  count = var.install_monitoring == true ? 1 : 0

  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "config.yaml" = <<-EOT
      enableUserWorkload: true
      prometheusOperator:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      prometheusK8s: 
        retention: 1y
        volumeClaimTemplate:
          spec:
            storageClassName: ibmc-vpc-block-retain-general-purpose
            volumeMode: Filesystem
            resources:
               requests:
                 storage: 100Gi
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      alertmanagerMain:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      kubeStateMetrics:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      openshiftStateMetrics:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      telemeterClient:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      k8sPrometheusAdapter:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      thanosQuerier:
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "cluster-monitoring-config"
      "namespace" = "openshift-monitoring"
    }
  }

  depends_on = [kubernetes_manifest.namespace_my_grafana_operator]
}

resource "kubernetes_manifest" "configmap_openshift_user_workload_monitoring_user_workload_monitoring_config" {
  count = var.install_monitoring == true ? 1 : 0

  manifest = {
    "apiVersion" = "v1"
    "data" = {
      "config.yaml" = <<-EOT
      prometheus:
        retention: 1y
        volumeClaimTemplate:
          spec:
            storageClassName: ibmc-vpc-block-retain-general-purpose
            volumeMode: Filesystem
            resources:
              requests:
                storage: 100Gi
        tolerations:
        - key: "logging-monitoring"
          operator: "Equal"
          value: "node"
          effect: "NoExecute"
      
      EOT
    }
    "kind" = "ConfigMap"
    "metadata" = {
      "name"      = "user-workload-monitoring-config"
      "namespace" = "openshift-user-workload-monitoring"
    }
  }

  depends_on = [kubernetes_manifest.configmap_openshift_monitoring_cluster_monitoring_config]
}

resource "kubernetes_manifest" "operatorgroup_my_grafana_operator_my_grafana_operator" {
  count = var.install_monitoring == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1"
    "kind"       = "OperatorGroup"
    "metadata" = {
      "name"      = "my-grafana-operator"
      "namespace" = "my-grafana-operator"
    }
    "spec" = {
      "targetNamespaces" = [
        "my-grafana-operator",
      ]
    }
  }

  depends_on = [kubernetes_manifest.configmap_openshift_user_workload_monitoring_user_workload_monitoring_config]
}

resource "kubernetes_manifest" "subscription_my_grafana_operator_my_grafana_operator" {
  count = var.install_monitoring == true ? 1 : 0

  manifest = {
    "apiVersion" = "operators.coreos.com/v1alpha1"
    "kind"       = "Subscription"
    "metadata" = {
      "name"      = "my-grafana-operator"
      "namespace" = "my-grafana-operator"
    }
    "spec" = {
      "channel"         = "v4"
      "name"            = "grafana-operator"
      "source"          = "community-operators"
      "sourceNamespace" = "openshift-marketplace"
    }
  }

  depends_on = [kubernetes_manifest.operatorgroup_my_grafana_operator_my_grafana_operator]
}