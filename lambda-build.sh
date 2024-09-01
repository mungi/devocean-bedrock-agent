#!/bin/bash
if ! hash aws 2>/dev/null || ! hash pip3 2>/dev/null; then
    echo "This script requires the AWS cli, and pip3 installed"
    exit 2
fi

set -eo pipefail

rm -rf ag_lambda_build ; mkdir ag_lambda_build ; cd ag_lambda_build
cp -r ../ag_lambda/* .
pip3 install --target . -r requirements.txt
cd ../

rm -rf cr_lambda_build ; mkdir cr_lambda_build ; cd cr_lambda_build
cp -r ../cr_lambda/* .
pip3 install --target . -r requirements.txt
cd ../

AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)

BUCKET_NAME=devocean-bedrock-agent-lambda-artifacts-${AWS_ACCOUNT}

if ! aws s3api head-bucket --bucket $BUCKET_NAME > /dev/null 2>&1; then
    aws s3 mb s3://${BUCKET_NAME} --region$AWS_REGION
fi 

aws cloudformation package \
 --template-file devocean-bedrock-agents-for-eks-tpl.yaml \
 --s3-bucket $BUCKET_NAME \
 --output-template-file devocean-bedrock-agents-for-eks-cfn.yaml \
 --region $AWS_REGION
