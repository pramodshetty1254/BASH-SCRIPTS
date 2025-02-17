#!/bin/bash

# Define multiple profiles
profiles=("nse-sap-stage")  # Add more profiles as needed
region="us-west-2"  # Default region (can be overridden per profile if needed)

for profile in "${profiles[@]}"; do
  echo "Fetching IO1 volumes for profile: $profile in region: $region..."

  # Fetch all IO1 volumes
  volumes=$(aws ec2 describe-volumes --region $region --profile $profile --filters Name=volume-type,Values=io1 --query 'Volumes[*].VolumeId' --output text)

  if [ -z "$volumes" ]; then
    echo "No IO1 volumes found for profile $profile in region $region."
    continue
  fi

  echo "The following IO1 volumes are detected:"
  echo "$volumes"

  # Ask for confirmation
  read -p "Do you want to tag these volumes as non-migratable? (yes/no): " confirm_tag
  if [[ "$confirm_tag" != "yes" ]]; then
    echo "Skipping tagging for profile $profile."
    continue
  fi

  # Tagging the IO2 volumes
  for volume in $volumes; do
    echo "Tagging volume $volume as non-migratable"
    aws ec2 create-tags --region $region --profile $profile --resources "$volume" --tags Key=cloudfix:dontFixit,Value=true
  done

done

echo "Tagging process completed for all profiles."
