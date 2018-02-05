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

loggingShape = "<SHAPE>"
monitoringShape = "<SHAPE>"

monitoring-instance-ad = "<LOGGING_AD>"
logging-instance-ad = "<MONITORING_AD>"
