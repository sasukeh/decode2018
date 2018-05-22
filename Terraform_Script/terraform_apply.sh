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

#https://www.terraform.io/docs/providers/azurerm/
export ARM_USE_MSI=true
export ARM_SUBSCRIPTION_ID="c70d8b28-a171-46dd-87df-1572bccdf375"
export ARM_TENANT_ID="72f988bf-86f1-41af-91ab-2d7cd011db47"
uname -a
pwd
echo "execute terraform plan"
az login --identity
terraform init 
terraform plan
# auto approve must be used here, cau'z no one can touch inside of VSTS jobs...
terraform apply -auto-approve
