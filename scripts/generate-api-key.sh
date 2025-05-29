#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BLAZE_DIR="$(dirname "$SCRIPT_DIR")"

# Function to generate or retrieve API key
generate_api_key() {
    # Using openssl for consistent key generation across platforms
    openssl rand -hex 32
}

# Function to update .env file
update_env_file() {
    echo "Updating .env file with API key"
    local env_file="${BLAZE_DIR}/.env"
    local api_key="$1"
    
    if [ -f "$env_file" ]; then
        # If API_KEY exists, update it; otherwise append it
        if grep -q "^API_KEY=" "$env_file"; then
            sed -i "s/^API_KEY=.*/API_KEY=$api_key/" "$env_file"
        else
            echo "API_KEY=$api_key" >> "$env_file"
        fi
    else
        # Create new .env file if it doesn't exist
        echo "API_KEY=$api_key" > "$env_file"
    fi
}

# Generate the key
API_KEY=$(generate_api_key)

# Check if update option is provided
if [ "$1" = "-u" ]; then
    update_env_file "$API_KEY"
fi

# Output the key
echo "$API_KEY" 