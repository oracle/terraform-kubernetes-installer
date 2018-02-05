terragrunt = {
  terraform {
    source = "<PROJECT_ROOT_DIR>/terraform-stack/"
  }
}

#--------------------------------------------------------------
# BMCS
#--------------------------------------------------------------
region            = "<REGION>"
tenancy_ocid      = "<TENANCY_OCID>"
compartment_ocid  = "<COMPARTMENT_OCID>"

disable_auto_retries = "false"

vcn_dns_name = "k8s"
domain_name = "k8s.oraclevcn.com"

label_prefix = "<ENV_PREFIX>-"

k8sMasterShape = "<K8S_MASTER_SHAPE>"
k8sWorkerShape = "<K8S_WORKER_SHAPE>"

k8sMasterShape = "<K8S_MASTER_SHAPE>"
k8sWorkerShape = "<K8S_WORKER_SHAPE>"

k8sWorkerAd1Count = "<K8S_WORKER_AD1_COUNT>"
k8sWorkerAd2Count = "<K8S_WORKER_AD2_COUNT>"
k8sWorkerAd3Count = "<K8S_WORKER_AD3_COUNT>"
k8sMasterAd1Count = "<K8S_MASTER_AD1_COUNT>"
k8sMasterAd2Count = "<K8S_MASTER_AD2_COUNT>"
k8sMasterAd3Count = "<K8S_MASTER_AD3_COUNT>"
etcdAd1Count = "0"
etcdAd2Count = "0"
etcdAd3Count = "0"
