#/bin/bash

workspace=$(terraform workspace show)
if [ $workspace != "dev" ]; then
    echo "Workspace is not DEV!"
    exit 64
fi
terraform apply -var-file=dev.tfvars