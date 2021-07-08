#!/bin/bash
set -e

echo "Starting build process..."

echo "Adding env variables..."
export PATH=/root/bin:$PATH

#Path to k8s config file
KUBECONFIG=/home/blockchain-automation-framework/build/config

echo "Validatin network yaml"
ajv validate -s /home/blockchain-automation-framework/platforms/network-schema.json -d /home/blockchain-automation-framework/build/network.yaml 

echo "Running the playbook..."
exec ansible-playbook -vv /home/blockchain-automation-framework/platforms/shared/configuration/site.yaml --inventory-file=/home/blockchain-automation-framework/platforms/shared/inventory/ -e "@/home/blockchain-automation-framework/build/network.yaml" -e 'ansible_python_interpreter=/usr/bin/python3'
