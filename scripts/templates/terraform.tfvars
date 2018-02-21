terragrunt = {
  terraform {
    source = "<PROJECT_ROOT_DIR>/"
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

#--------------------------------------------------------------
# Compute shapes
#--------------------------------------------------------------
k8sMasterShape = "<K8S_MASTER_SHAPE>"
k8sWorkerShape = "<K8S_WORKER_SHAPE>"
etcdShape = "<ETCD_SHAPE>"


#--------------------------------------------------------------
# Compute counts
#--------------------------------------------------------------
k8sWorkerAd1Count = "<K8S_WORKER_AD1_COUNT>"
k8sWorkerAd2Count = "<K8S_WORKER_AD2_COUNT>"
k8sWorkerAd3Count = "<K8S_WORKER_AD3_COUNT>"
k8sMasterAd1Count = "<K8S_MASTER_AD1_COUNT>"
k8sMasterAd2Count = "<K8S_MASTER_AD2_COUNT>"
k8sMasterAd3Count = "<K8S_MASTER_AD3_COUNT>"
etcdAd1Count = "<ETCD_AD1_COUNT>"
etcdAd2Count = "<ETCD_AD2_COUNT>"
etcdAd3Count = "<ETCD_AD3_COUNT>"

#--------------------------------------------------------------
# Load Balancers
#--------------------------------------------------------------
master_oci_lb_enabled = "<K8S_MASTER_LB_ENABLED>"
k8sMasterLBShape = "<K8S_MASTER_LB_SHAPE>"

#--------------------------------------------------------------
# Certs and keys
#--------------------------------------------------------------
ca_cert	= "<CA_CERT>"
ca_key	= "<CA_KEY>"
api_server_private_key	= "<API_SERVER_PRIVATE_KEY>"
api_server_cert	= "<API_SERVER_CERT>"
api_server_admin_token	= "<API_SERVER_ADMIN_TOKEN>"
ssh_private_key	= "<SSH_PRIVATE_KEY>"
ssh_public_key_openssh	= "<SSH_PUBLIC_KEY_OPENSSH>"

#--------------------------------------------------------------
# Compute images
#--------------------------------------------------------------
master_ol_image_name = "<MASTER_OL_IMAGE_NAME>"
worker_ol_image_name = "<WORKER_OL_IMAGE_NAME>"
etcd_ol_image_name = "<ETCD_OL_IMAGE_NAME>"
nat_ol_image_name = "<NAT_OL_IMAGE_NAME>"

#--------------------------------------------------------------
# Security rules
#--------------------------------------------------------------
etcd_cluster_ingress = "<ETCD_CLUSTER_INGRESS>"
etcd_ssh_ingress = "<ETCD_SSH_INGRESS>"
master_ssh_ingress = "<MASTER_SSH_INGRESS>"
master_https_ingress = "<MASTER_HTTPS_INGRESS>"
worker_ssh_ingress = "<WORKER_SSH_INGRESS>"
worker_nodeport_ingress = "<WORKER_NODEPORT_INGRESS>"
public_subnet_ssh_ingress = "<PUBLIC_SUBNET_SSH_INGRESS>"
public_subnet_http_ingress = "<PUBLIC_SUBNET_HTTP_INGRESS>"
public_subnet_https_ingress = "<PUBLIC_SUBNET_HTTPS_INGRESS>"

#--------------------------------------------------------------
# NAT-related settings
#--------------------------------------------------------------
dedicated_nat_subnets = "<DEDICATED_NAT_SUBNETS>"
natInstanceShape = "<NAT_INSTANCE_SHAPE>"
nat_instance_ad1_enabled = "<NAT_INSTANCE_AD1_ENABLED>"
nat_instance_ad2_enabled = "<NAT_INSTANCE_AD2_ENABLED>"
nat_instance_ad3_enabled = "<NAT_INSTANCE_AD3_ENABLED>"

#--------------------------------------------------------------
# Network access
#--------------------------------------------------------------
control_plane_subnet_access = "<CONTROL_PLANE_SUBNET_ACCESS>"
k8s_master_lb_access = "<K8S_MASTER_LB_ACCESS>"

#--------------------------------------------------------------
# Volume attachments
#--------------------------------------------------------------
worker_iscsi_volume_create = "<WORKER_ISCSI_VOLUME_CREATE>"
worker_iscsi_volume_size = "<WORKER_ISCSI_VOLUME_SIZE>"
worker_iscsi_volume_mount = "<WORKER_ISCSI_VOLUME_MOUNT>"
etcd_iscsi_volume_create = "<ETCD_ISCSI_VOLUME_CREATE>"
etcd_iscsi_volume_size = "<ETCD_ISCSI_VOLUME_SIZE>"
