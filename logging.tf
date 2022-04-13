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

#####################################################################################
# Cannot apply CRD and a CR using it in the same plan/apply due to SSA 
# (see: https://github.com/hashicorp/terraform-provider-kubernetes/issues/1367)
#####################################################################################
# resource "kubernetes_manifest" "clusterlogging_openshift_logging_instance" {
#   count = var.install_logging == true ? 1 : 0

#   manifest = {
#     "apiVersion" = "logging.openshift.io/v1"
#     "kind"       = "ClusterLogging"
#     "metadata" = {
#       "name"      = "instance"
#       "namespace" = "openshift-logging"
#     }
#     "spec" = {
#       "collection" = {
#         "logs" = {
#           "fluentd" = {}
#           "type"    = "fluentd"
#         }
#       }
#       "curation" = {
#         "curator" = {
#           "schedule" = "30 3 * * *"
#         }
#         "type" = "curator"
#       }
#       "logStore" = {
#         "elasticsearch" = {
#           "nodeCount" = 3
#           "proxy" = {
#             "resources" = {
#               "limits" = {
#                 "memory" = "256Mi"
#               }
#               "requests" = {
#                 "memory" = "256Mi"
#               }
#             }
#           }
#           "redundancyPolicy" = "SingleRedundancy"
#           "resources" = {
#             "limits" = {
#               "memory" = "16Gi"
#             }
#             "requests" = {
#               "memory" = "16Gi"
#             }
#           }
#           "storage" = {
#             "size"             = "200G"
#             "storageClassName" = "ibmc-vpc-block-general-purpose"
#           }
#         }
#         "retentionPolicy" = {
#           "application" = {
#             "maxAge" = "1d"
#           }
#           "audit" = {
#             "maxAge" = "7d"
#           }
#           "infra" = {
#             "maxAge" = "7d"
#           }
#         }
#         "type" = "elasticsearch"
#       }
#       "managementState" = "Managed"
#       "visualization" = {
#         "kibana" = {
#           "replicas" = 1
#         }
#         "type" = "kibana"
#       }
#     }
#   }

#   depends_on = [kubernetes_manifest.subscription_openshift_logging_cluster_logging]
# }
#####################################################################################

resource "null_resource" "clusterlogging_openshift_logging_instance" {
  count = var.install_logging == true ? 1 : 0

  triggers = {
    "cluster_name" = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<EOF

ibmcloud oc cluster config --cluster ${CLUSTER_NAME} --admin -q

oc config current-context 2> errors.txt 
if [[ -f errors.txt && -s errors.txt ]]; then
  cat errors.txt
  exit 
fi

echo "Verifying Operator Installation for $(oc config current-context)"
echo "--------------------------------------"

IS_INSTALLED=false
RETRY_LIMIT=15
i=0

while [[ "$IS_INSTALLED" == "false" ]] && [ "$i" -lt "$RETRY_LIMIT" ]; 
do
  RESPONSE=$(oc get csv -n openshift-logging | grep "openshift-logging")

  if [[ "$RESPONSE" == "" ]]; then 
    echo "* ($((i+1))/$RETRY_LIMIT) Installed ... false"
    IS_INSTALLED=false
    # sleep 10
  else 
    echo "* ($((i+1))/$RETRY_LIMIT) Installed ... true"
    IS_INSTALLED=true
  fi 

  ((i++))
done

if [[ "$IS_INSTALLED" == "false" ]] && [ "$i" -eq "$RETRY_LIMIT" ]; then 
  echo "Exhausted max attempts waiting for operator installation (retry limit: $RETRY_LIMIT)"
fi

echo 'apiVersion: "logging.openshift.io/v1"
kind: "ClusterLogging"
metadata:
  name: "instance" 
  namespace: "openshift-logging"
spec:
  collection:
    logs:
      type: "fluentd"  
      fluentd: {}
  curation:
    type: "curator"
    curator:
      schedule: "30 3 * * *"
  logStore:
    type: "elasticsearch"  
    elasticsearch:
      nodeCount: 3
      proxy: 
        resources:
          limits:
            memory: 256Mi
          requests:
             memory: 256Mi
      redundancyPolicy: "SingleRedundancy"
      resources: 
        limits:
          memory: "16Gi"
        requests:
          memory: "16Gi"
      storage:
        storageClassName: "ibmc-vpc-block-general-purpose" 
        size: 200G
    retentionPolicy: 
      application:
        maxAge: 1d
      infra:
        maxAge: 7d
      audit:
        maxAge: 7d
  managementState: "Managed"  
  visualization:
    type: "kibana"
    kibana:
      replicas: 1' > instance.yaml

echo "Creating Cluster Logging instance"
oc create -f instance.yaml

sleep 60

echo "Retrieving cluster logging pods"
oc get pods -n openshift-logging

EOF
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
FILE="instance.yaml"
if [ ! -f "$FILE" ]; then 
  echo "$FILE does not exist, please configure logging to run this step"
  exit 0; # non-error
fi

echo "$FILE exists, destroying cluster logging instance"
oc delete -f instance.yaml

sleep 60 

echo "Retrieving cluster logging pods"
oc get pods -n openshift-logging

EOF
  }

  depends_on = [kubernetes_manifest.subscription_openshift_logging_cluster_logging]
}