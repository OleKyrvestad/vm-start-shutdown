#!/bin/bash

vmTag=$1        # The tag to check (e.g., vm-automation-start-stop)
vmTagValue=$2   # The tag value to match (e.g., true)

VM_IDS=()
VM_NAMES=()

# Get the list of VMs with the specific tag and value
VM_IDS=$(az vm list --query "[?tags.\`$vmTag\` == \`$vmTagValue\`].id" -o tsv)
VM_NAMES=$(az vm list --query "[?tags.\`$vmTag\` == \`$vmTagValue\`].name" -o tsv)

# Check if any VMs were found
if [ -z "$VM_IDS" ]; then
    echo "No VMs found matching the criteria."
    exit 0
fi

# List VMs to process
echo "List of VMs to process:"
echo "$VM_NAMES" | sed 's/^/ - /'
echo -e "\033[36mProcessing VMs, please wait...\033[0m"

# Start the VMs
az vm start --ids $VM_IDS &>/dev/null

# Initialize an array to keep track of VMs that are not successfully started
FAILED_VMS=()

# Check the provisioning state of each VM
for VM_ID in $VM_IDS; do
    VM_NAME=$(az vm show --ids "$VM_ID" --query "name" -o tsv)
    VM_PROVISIONING_STATE=$(az vm show --ids "$VM_ID" --query "provisioningState" -o tsv)

    # Debug output for VM name and provisioning state
    echo "Checking VM: $VM_NAME"
    echo "Provisioning State: $VM_PROVISIONING_STATE"

    if [ "$VM_PROVISIONING_STATE" == "Succeeded" ]; then
        echo -e "\033[36mVM $VM_NAME is successfully started and in Succeeded state.\033[0m"  # Cyan color for success
    else
        echo -e "\033[31mVM $VM_NAME did not reach Succeeded state. Current provisioning state: $VM_PROVISIONING_STATE\033[0m"
        # Add the VM to the failed list
        FAILED_VMS+=("$VM_NAME")
    fi
done

# Check if there are any failed VMs and print them
if [ ${#FAILED_VMS[@]} -ne 0 ]; then
    echo -e "\033[31mThe following VMs failed to start successfully:\033[0m"
    for VM in "${FAILED_VMS[@]}"; do
        echo -e "\033[31m - $VM\033[0m"
    done
else
    echo -e "\033[32mAll VMs are successfully started and in Succeeded state.\033[0m"  # Green color for all successful
fi
