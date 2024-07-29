#!/bin/bash

# Set the AWS profile to use
AWS_PROFILE="main"
AWS_REGION="ap-east-1"

# List all S3 buckets
buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text --profile $AWS_PROFILE --region $AWS_REGION)

for bucket in $buckets; do
    echo "Processing bucket: $bucket"
    
    # Check if the bucket already has a Name tag
    name_tag=$(aws s3api get-bucket-tagging --bucket $bucket --query "TagSet[?Key=='Name'].Value" --output text --profile $AWS_PROFILE --region $AWS_REGION 2>/dev/null)
    
    if [ "$name_tag" ]; then
        echo "Bucket $bucket already has a Name tag: $name_tag"
    else
        echo "Adding Name tag to bucket $bucket"
        
        # Get the existing tags
        existing_tags=$(aws s3api get-bucket-tagging --bucket $bucket --query "TagSet" --output json --profile $AWS_PROFILE --region $AWS_REGION 2>/dev/null)
        
        # If there are existing tags, include them
        if [ "$existing_tags" ]; then
            new_tags=$(echo $existing_tags | jq '. += [{"Key": "Name", "Value": "'$bucket'"}]')
        else
            new_tags=$(echo '[{"Key": "Name", "Value": "'$bucket'"}]' | jq '.')
        fi
        
        # Convert JSON array to string and escape it correctly
        new_tags_string=$(echo $new_tags | jq -c '.')

        # Update the bucket tags
        aws s3api put-bucket-tagging --bucket $bucket --tagging "{\"TagSet\": $new_tags_string}" --profile $AWS_PROFILE --region $AWS_REGION
        echo "Added Name tag to bucket $bucket"
    fi
done
