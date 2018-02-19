terragrunt = {
  terraform {
    source = "../../../terraform-stack/"
  }
}

#--------------------------------------------------------------
# BMCS
#--------------------------------------------------------------
region            = "<REGION>"
tenancy_ocid      = "ocid1.tenancy.oc1..aaaaaaaaqzv7hhoe4sypzyitsoubjf6hbmr26sxrw452p4slslarsbqz25bq"
compartment_ocid  = "ocid1.compartment.oc1..aaaaaaaa26lan4rbf3hmfr36pr3umppk2bucxeq7vmg7n5a2jqlma4tjjcqq"

disable_auto_retries = "false"

vcn_dns_name = "k8s"

domain_name = "<EXTERNAL_DOMAIN_NAME>"

label_prefix = "<ENV_PREFIX>-"

loggingShape = "VM.Standard1.4"
monitoringShape = "VM.Standard1.4"

use_block_storage = "true"
loggingBlockVolumeSize = "5242880"
monitoringBlockVolumeSize = "1048576"

monitoring-instance-ad = "<MONITORING_AD>"
logging-instance-ad = "<LOGGING_AD>"
