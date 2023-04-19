#!/bin/sh
set -e

poetry env use python3.10 && poetry install --no-root

# Check if the "redis" container is running
if ! docker ps --filter "status=running" --format "{{.Names}}" | grep -q "redis"; then
  # If the "redis" container is not running, start it using docker-compose
  docker-compose -f ./examples/docker/redis/docker-compose.yml up -d
else
  echo "The 'redis' container is already running."
fi

echo "Please enter your OpenAI API key found here: https://platform.openai.com/account/api-keys:"
read -r OPENAI_API_KEY

# Export the OPENAI_API_KEY environment variable
export OPENAI_API_KEY
export DATASTORE=redis 
export BEARER_TOKEN=footoken 
export PLUGIN_HOSTNAME=https://$CODESPACE_NAME-8000.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN 

./hostconfig.sh

echo "Click on GitHub Codespaces PORTS tab.  Right click on port 8000, and set Port Visibility to Public. Once Port 8000 if Public, press Enter to continue..."
read -r placeholder_var

echo "Use the following URL to use this plugin in the OpenAI Plugin store:"
echo $PLUGIN_HOSTNAME

echo "Starting the Plugin API..."
echo "Once it has started, Open a new terminal and run the ./initplugin.sh file"
echo
echo
poetry run start
