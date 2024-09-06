#!/bin/bash

# If no arguments passed, read from vm-list.txt
if [ -z "$1" ]; then
    echo "No VM names provided, reading from vm-list.txt"
    mapfile -t vmNames < vm-list.txt  # Read all lines into the vmNames array
else
    vmNames=("$@")  # Use the provided VM names
fi

VM_IDS=()
VM_NAMES=()

# Check if vmNames are provided
if [ ${#vmNames[@]} -gt 0 ]; then
    
    # Loop through each VM name in the list
    for vmName in "${vmNames[@]}"; do
        # Get the VM ID and Name for each VM
        ID=$(az vm list --query "[?name == '$vmName'].id" -o tsv)
        NAME=$(az vm list --query "[?name == '$vmName'].name" -o tsv)

        if [ -n "$ID" ]; then
            # Append results to the arrays
            VM_IDS+=("$ID")
            VM_NAMES+=("$NAME")
        else
            echo "VM $vmName not found."
        fi
    done
else
    echo "Please provide VM name(s)."
    exit 1
fi

# Check if any VMs were found
if [ ${#VM_IDS[@]} -eq 0 ]; then
    echo "No VMs found matching the criteria."
    exit 0
fi

# List VMs to process
echo "List of VMs to process:"
for vmName in "${VM_NAMES[@]}"; do
    echo " - $vmName"
done
echo -e "\033[36mProcessing VMs, please wait...\033[0m"

# Deallocate the VMs
az vm deallocate --ids ${VM_IDS[@]} &>/dev/null

# Initialize an array to keep track of VMs that are not deallocated
FAILED_VMS=()

# Check the provisioning state of each VM
for VM_ID in "${VM_IDS[@]}"; do
    VM_NAME=$(az vm show --ids "$VM_ID" --query "name" -o tsv)
    VM_PROVISIONING_STATE=$(az vm get-instance-view --ids "$VM_ID" --query "instanceView.statuses[?code=='PowerState/deallocated'].displayStatus" -o tsv)

    # Debug output for VM name and provisioning state
    echo "Checking VM: $VM_NAME"
    echo "Provisioning State: $VM_PROVISIONING_STATE"

    if [ "$VM_PROVISIONING_STATE" == "VM deallocated" ]; then
        echo -e "\033[36mVM $VM_NAME is deallocated.\033[0m"  # Cyan color for success
    else
        echo -e "\033[31mVM $VM_NAME is NOT deallocated. Current provisioning state: $VM_PROVISIONING_STATE\033[0m"
        # Add the VM to the failed list
        FAILED_VMS+=("$VM_NAME")
    fi
done

# Check if there are any failed VMs and print them
if [ ${#FAILED_VMS[@]} -ne 0 ]; then
    echo -e "\033[31mThe following VMs failed to deallocate:\033[0m"
    for VM in "${FAILED_VMS[@]}"; do
        echo -e "\033[31m - $VM\033[0m"
    done
else
    echo -e "\033[32mAll VMs are successfully deallocated.\033[0m"  # Green color for all successful
fi
