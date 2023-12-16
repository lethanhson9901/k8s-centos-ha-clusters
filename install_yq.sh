#!/bin/bash

# Bash script to install yq on CentOS

# Define the yq version to install
YQ_VERSION="4.2.0" # Replace with the desired version

# Download yq binary from GitHub releases
echo "Downloading yq version $YQ_VERSION..."
wget https://github.com/mikefarah/yq/releases/download/v$YQ_VERSION/yq_linux_amd64 -O /usr/local/bin/yq

# Verify if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download yq. Exiting."
    exit 1
fi

# Make the binary executable
echo "Making yq executable..."
chmod +x /usr/local/bin/yq

# Verify the installation
echo "Verifying the installation..."
/usr/local/bin/yq --version

# Check if yq is available in the current shell
if [ $? -eq 0 ]; then
    echo "yq version $YQ_VERSION installed successfully."
else
    echo "Failed to verify yq installation. Please check the installation steps."
fi
