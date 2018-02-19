FROM fedora:latest

 ENV LANG=C.UTF-8 \
     http_proxy=http://www-proxy.us.oracle.com:80 \
     https_proxy=http://www-proxy.us.oracle.com:80 \
     no_proxy="localhost,127.0.0.1,.oraclecorp.com,.grungy.us,docker"

 COPY cacerts.pem /etc/pki/ca-trust/source/anchors/cacerts.pem
 RUN update-ca-trust force-enable

 # ---
 # Install A few required base packages
 # Put 'dnf clean all' at the end of the docker file
 # ---
 RUN set -ex && \
   dnf -vvv install -y openssh-clients ansible curl python-pip gcc python-devel openssl-devel libffi-devel && \
   pip install --upgrade pip && \
   pip install paramiko netaddr oraclebmc futures==3.1.1 && yum install -y git && \
   dnf clean all

 RUN yum install -y unzip
 # Installs terraform.
 RUN curl -LO https://releases.hashicorp.com/terraform/0.10.4/terraform_0.10.4_linux_amd64.zip
 RUN unzip terraform_0.10.4_linux_amd64.zip
 RUN mv terraform /usr/bin/

 # Installs terragrunt
 RUN curl -LO https://github.com/gruntwork-io/terragrunt/releases/download/v0.13.3/terragrunt_linux_amd64
 RUN mv terragrunt_linux_amd64 /usr/bin/terragrunt
 RUN chmod +x /usr/bin/terragrunt

 # Installs the BMC terraform provider.
 RUN curl -LO  https://github.com/oracle/terraform-provider-baremetal/releases/download/v1.0.18/linux.tar.gz
 RUN tar -xzvf linux.tar.gz -C /
 RUN echo 'providers { baremetal = "/linux_amd64/terraform-provider-baremetal" }' > ~/.terraformrc

 # Installs the kubectl client
 RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.7.0/bin/linux/amd64/kubectl
 RUN chmod +x ./kubectl
 RUN mv ./kubectl /usr/local/bin/kubectl

 ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
