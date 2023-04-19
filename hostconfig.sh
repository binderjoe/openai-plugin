#!/bin/sh
set -e

# Check if CODESPACES environment variable is set to true
# Provide a default value of "false" if CODESPACES is not set
if [ "${CODESPACES:-false}" = "true" ]; then
  # If CODESPACES is true and PLUGIN_HOSTNAME is undefined or empty, set PLUGIN_HOSTNAME
  if [ -z "$PLUGIN_HOSTNAME" ]; then
    # Check if CODESPACE_NAME and GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN are set
    if [ -z "$CODESPACE_NAME" ] || [ -z "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
      echo "CODESPACE_NAME and/or GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN environment variables are not set."
      exit 1
    fi
    # Set PLUGIN_HOSTNAME to the expanded version of the URL
    PLUGIN_HOSTNAME="https://$CODESPACE_NAME-8000.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
  fi
else
  # If CODESPACES is not true, check if PLUGIN_HOSTNAME is set
  if [ -z "$PLUGIN_HOSTNAME" ]; then
    echo "PLUGIN_HOSTNAME environment variable is not set."
    exit 1
  fi
fi


# Input JSON file
json_input_file="./.well-known/ai-plugin.json"

# Input YAML file
yaml_input_file="./.well-known/openapi.yaml"

# Create temporary files to store the modified JSON and YAML
temp_json_file=$(mktemp)
temp_yaml_file=$(mktemp)

# Read the JSON file and perform the substitutions using jq
jq --arg plugin_hostname "$PLUGIN_HOSTNAME" '
  .api.url = ($plugin_hostname + "/.well-known/openapi.yaml") |
  .logo_url = ($plugin_hostname + "/.well-known/logo.png")
' "$json_input_file" > "$temp_json_file"

# Find the line number where the "servers:" key is located in the YAML file
servers_line_number=$(grep -n "servers:" "$yaml_input_file" | cut -d: -f1)

# Update the YAML file using sed and awk
awk -v line_number="$servers_line_number" -v plugin_hostname="$PLUGIN_HOSTNAME" '
  NR == line_number + 1 {
    sub(/url: .*/, "url: " plugin_hostname)
  }
  { print }
' "$yaml_input_file" > "$temp_yaml_file"

# Overwrite the original JSON file with the modified contents
mv "$temp_json_file" "$json_input_file"

# Overwrite the original YAML file with the modified contents
mv "$temp_yaml_file" "$yaml_input_file"

# Print success messages
echo "$json_input_file has been updated successfully."
echo "$yaml_input_file file has been updated successfully."
