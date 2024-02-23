#!/bin/bash
# Automation script for CloudFormation templates. 
#
# Parameters
#   $1: Execution mode. Valid values: deploy, delete.
#
# Usage examples:
#   ./run.sh deploy 
#   ./run.sh delete
#

NETWORK_STACK_TEMPLATE="network.yml"
NETWORK_STACK_PARAMETERS="network-parameters.json"
APPLICATION_STACK_TEMPLATE="udagram.yml"
APPLICATION_STACK_PARAMETERS="udagram-parameters.json"

NETWORK_STACK_NAME="UdagramNetworkStack"
APPLICATION_STACK_NAME="UdagramApplicationStack"
REGION=us-east-1

S3_BUCKET=udagram-s3-bucket-6522-4509-4333
DESTINATION_KEY=udagram/index.html

if [[ $1 != "deploy" && $1 != "delete" ]]; then
    echo "ERROR: Incorrect execution mode. Valid values: deploy, delete." >&2
    exit 1
fi

if [ $1 == "deploy" ]
then
    echo "Deploying network stack..."
    aws cloudformation deploy \
        --stack-name $NETWORK_STACK_NAME \
        --template-file $NETWORK_STACK_TEMPLATE \
        --parameter-overrides file://$NETWORK_STACK_PARAMETERS \
        --region $REGION

    echo "Waiting for network stack deployment to complete..."
    aws cloudformation wait stack-create-complete --stack-name $NETWORK_STACK_NAME

    echo "Deploying application stack..."
    aws cloudformation deploy \
        --stack-name $APPLICATION_STACK_NAME \
        --template-file $APPLICATION_STACK_TEMPLATE \
        --parameter-overrides file://$APPLICATION_STACK_PARAMETERS \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION

    echo "Waiting for application stack deployment to complete..."
    aws cloudformation wait stack-create-complete --stack-name $APPLICATION_STACK_NAME

    echo "Stack deployment completed successfully."

    echo "Movin index.html to s3 bucket"
    aws s3 mv $source_file s3://$S3_BUCKET/$DESTINATION_KEY
    if [ $? -eq 0 ]; then
        echo "File moved to S3 successfully"
    else
        echo "Error: File move to S3 failed"
    fi
fi
if [ $1 == "delete" ]
then
    echo "Empty S3 bucket"
    aws s3 rm s3://$s3_bucket --recursive
    echo "Bucket emptied successfully"

    echo "Deleting application stack..."
    aws cloudformation delete-stack --stack-name $APPLICATION_STACK_NAME --region $REGION

    echo "Waiting for application stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $APPLICATION_STACK_NAME --region $REGION

    echo "Deleting network stack..."
    aws cloudformation delete-stack --stack-name $NETWORK_STACK_NAME --region $REGION

    echo "Waiting for network stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $NETWORK_STACK_NAME --region $REGION

    echo "Stack deletion completed successfully."

    if [ $? -eq 0 ]; then
        echo "Bucket emptied successfully"
    else
        echo "Error: Failed to empty the bucket"
    fi
fi
