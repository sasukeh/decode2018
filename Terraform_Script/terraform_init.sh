#
# Usage:
#   
#
if [ ! `command -v unzip` ] ; then
  sudo apt update
  sudo apt install -y zip unzip
fi

if [ ! `command -v terraform` ] ; then
  wget https://releases.hashicorp.com/terraform/0.11.7/terraform_0.11.7_linux_amd64.zip
  unzip terraform_0.11.7_linux_amd64.zip
  sudo mv terraform /usr/bin/
fi

export ARM_USE_MSI=true
uname -a
pwd
echo "execute terraform initialization"
terraform init
