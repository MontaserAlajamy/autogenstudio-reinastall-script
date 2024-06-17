#!/bin/bash

ENV_NAME="ag" 
PORT=8081

# Check if conda is installed
if ! command -v conda &> /dev/null
then
    echo "ERROR: Conda is not installed. Please install Conda before proceeding."
    exit 1
fi

# Check and create the Conda environment
if ! conda info --envs | grep -q "^$ENV_NAME "; then
    echo "Creating Conda environment: $ENV_NAME"
    conda create -n $ENV_NAME python=3.11 -y
else
    echo "Conda environment '$ENV_NAME' already exists."
fi

# Activate the Conda environment
echo "Activating Conda environment: $ENV_NAME"
source activate $ENV_NAME || conda activate $ENV_NAME

# Get the local IP address (more reliable method)
IP_ADDRESS=$(hostname -I | awk '{print $1}') 
echo "Detected IP address: $IP_ADDRESS"

# Check for OpenAI API Key in environment variable
if [[ -z "$OPENAI_API_KEY" ]]; then
    echo "ERROR: OPENAI_API_KEY environment variable not set."
    exit 1
else
    echo "Using existing OPENAI_API_KEY environment variable."
fi

# Uninstall existing AutoGen Studio
echo "Uninstalling existing AutoGen Studio (if found)..."
pip uninstall autogenstudio -y  # Direct uninstallation

# Upgrade AutoGen and AutoGen Studio to latest versions
echo "Installing AutoGen and AutoGen Studio..."
pip install -U autogen autogenstudio

# Function to launch AutoGen Studio with port selection and error handling
launch_autogen() {
    local port=$1

    echo "Attempting to launch AutoGen Studio UI on port $port..."
    if autogenstudio ui --port $port --host $IP_ADDRESS; then
        echo "App running at http://$IP_ADDRESS:$port/"
    else
        if [[ "$port" -lt 65535 ]]; then
            echo "Port $port is in use. Trying next port..."
            launch_autogen $((port + 1)) 
        else
            echo "ERROR: Could not find an available port. Please check your network configuration."
        fi
    fi
}

# Start on the specified port and try higher ports if needed
launch_autogen $PORT

# Graceful shutdown on interrupt (Ctrl+C)
trap "echo 'Stopping AutoGen Studio...'; autogenstudio shutdown; echo 'App stopped.'" SIGINT

# Wait for application shutdown
wait 
