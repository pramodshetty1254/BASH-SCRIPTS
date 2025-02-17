#!/bin/bash

# Variables
CONFIG_FILE="/etc/otel/collector/agent_config.yaml"


# Check if the file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: $CONFIG_FILE not found."
  exit 1
fi
# Search and replace
echo "Running sed command to replace text..."
sed -i.$(date +"%Y-%m-%d_%H-%M").bak '/splunk_hec:/,/sourcetype: "otel"/{
/sourcetype: "otel"/{
a\
    profiling_data_enabled: false
}
}' "$CONFIG_FILE"

if [ $? -eq 0 ]; then
  echo "update_status=success"
else
  echo "update_status=fail"
fi
