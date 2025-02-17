#!/bin/bash

# Define multiple profiles
profiles=("nse-dev-us-east-2")  # Add more profiles as needed
region="us-east-2"  # Default region (can be overridden per profile if needed)

for profile in "${profiles[@]}"; do
  echo "Fetching AMIs owned by you for profile: $profile in region: $region..."

  # Fetch AMIs owned by the user
  ami_ids=$(aws ec2 describe-images --owners self --region $region --profile $profile --query 'Images[*].ImageId' --output text)

  if [ -z "$ami_ids" ]; then
    echo "No AMIs found for profile $profile in region $region."
  else
    echo "The following AMIs are owned by you and will be deregistered:"
    echo "$ami_ids"

    # Ask for confirmation before deregistering AMIs
    read -p "Do you want to deregister these AMIs? (yes/no): " confirm_ami
    if [[ "$confirm_ami" == "yes" ]]; then
      for ami_id in $ami_ids; do
        # Fetch the snapshot associated with the AMI
        snapshot_id=$(aws ec2 describe-images --image-ids $ami_id --region $region --profile $profile --query 'Images[*].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)

        echo "Deregistering AMI $ami_id..."
        aws ec2 deregister-image --image-id $ami_id --region $region --profile $profile
        echo "AMI $ami_id has been deregistered."

        # Delete associated snapshot
        if [ -n "$snapshot_id" ]; then
          echo "Deleting associated snapshot $snapshot_id..."
          aws ec2 delete-snapshot --snapshot-id $snapshot_id --region $region --profile $profile
          echo "Deleted snapshot $snapshot_id."
        fi
      done
    else
      echo "Skipping AMI deregistration and associated snapshot deletion for profile $profile."
    fi
  fi

  echo "Fetching snapshots not associated with AMIs for profile: $profile in region: $region..."

  # Fetch only snapshots owned by the user that are NOT associated with an AMI
  snapshot_ids=$(aws ec2 describe-snapshots --region $region --profile $profile --owner self --query 'Snapshots[*].SnapshotId' --output text)

  if [ -z "$snapshot_ids" ]; then
    echo "No standalone snapshots owned by you found in profile $profile."
    continue
  fi

  echo "The following standalone snapshots are owned by you and will be considered for deletion:"
  echo "$snapshot_ids"

  # Ask for confirmation before deletion
  read -p "Do you want to delete these standalone snapshots? (yes/no): " confirm_snapshots

  if [[ "$confirm_snapshots" != "yes" ]]; then
    echo "Skipping snapshot deletion for profile $profile."
    continue
  fi

  # Delete standalone snapshots
  for snapshot_id in $snapshot_ids; do
    aws ec2 delete-snapshot --region $region --profile $profile --snapshot-id $snapshot_id
    echo "Deleted snapshot $snapshot_id from profile $profile"
  done

  echo "All selected standalone snapshots for profile $profile have been deleted."
done

echo "AMI and snapshot cleanup process completed for all profiles."
