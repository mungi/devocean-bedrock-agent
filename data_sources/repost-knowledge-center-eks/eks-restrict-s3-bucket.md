Original URL: <https://repost.aws/knowledge-center/eks-restrict-s3-bucket>

# How do I use the IAM roles for service accounts (IRSA) feature with Amazon EKS to restrict access to an Amazon S3 bucket?

I want to restrict the access of an Amazon Simple Storage Service (Amazon S3) bucket at the pod level in Amazon Elastic Kubernetes Service (Amazon EKS). I also want to keep minimum privileges for my application with AWS Identity and Access Management (IAM) roles for service accounts (IRSA).

## Resolution

**Important:** Before you use IRSA with Amazon EKS, you must [create an IAM OIDC provider for your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>).

### Create an IAM policy and role

1\. Create a JSON file called **iam-policy.json**.

The following example policy restricts Amazon S3 and Amazon DynamoDB permissions. IAM users are allowed to [access one S3 bucket](<https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-policies-s3.html#iam-policy-ex0>) and [access a specific DynamoDB table](<https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_dynamodb_specific-table.html>).
    
    
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "ListAndDescribe",
                "Effect": "Allow",
                "Action": [
                    "dynamodb:List*",
                    "dynamodb:Describe*"
                ],
                "Resource": "arn:aws:dynamodb:*:*:table/YOUR_TABLE"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": "arn:aws:s3:::YOUR_BUCKET"
            },
            {
                "Sid": "List",
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:GetObjectVersion"
                ],
                "Resource": "arn:aws:s3:::YOUR_BUCKET/*"
            }
        ]
    }

**Note:** Replace **YOUR_TABLE** with your table. Replace **YOUR_NAMESPACE** with your namespace.

2\. Create an IAM policy called **YOUR-IAM-POLICY**.
    
    
    $ aws iam create-policy \
        --policy-name YOUR-IAM-POLICY \
        --policy-document file://iam-policy.json

**Note:** Replace **YOUR-IAM-POLICY** with your policy name.

3\. Use the IAM console to [create an IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>) for your service account, and then [annotate a service account](<https://docs.aws.amazon.com/eks/latest/userguide/configure-sts-endpoint.html>) with that IAM role. Or, use **eksctl** to create an IAM role for your service account. For example:
    
    
    $ eksctl create iamserviceaccount \
      --name YOUR-SERVICEACCOUNT \
      --namespace YOUR-NAMESPACE \
      --cluster YOUR-CLUSTER \
      --attach-policy-arn arn:aws:iam::1111122222:policy/YOUR-IAM-POLICY \
      --approve

**Note:** Replace **1111122222** your Amazon Resource Name (ARN). You can also create an IAM role for your service account using the [IAM console](<https://console.aws.amazon.com/iam>).

### Create an Amazon EKS pod

In the following steps, replace your own application with an [aws-cli image](<https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html>). This allows you to check if your pod can assume the specified IAM role with the correct IAM permissions.

1\. Create a YAML file called **aws-cli-pod.yaml**. 
    
    
    apiVersion: v1
    kind: Pod
    metadata:
      name: aws-cli
      namespace: YOUR_NAMESPACE
    spec:
      serviceAccountName: YOUR_SERVICEACCOUNT
      containers:
      - name: aws-cli
        image: amazon/aws-cli:latest
        command:
          - sleep
          - "3600"
        imagePullPolicy: IfNotPresent
      restartPolicy: Always

**Note** : Replace **YOUR_NAMESPACE** with your namespace. Replace **SERVICE_ACCOUNT** with your Kubernetes service account name. 

2\. Create an Amazon EKS pod:
    
    
    $ kubectl apply -f ./aws-cli.yaml

### Test your Amazon EKS pod

Confirm that your pod uses the correct IAM role with limit actions for Amazon S3 and DynamoDB. In the following example, the pod can list only the S3 bucket (**YOUR_BUCKET**) and DynamoDB table (**YOUR_TABLE**).

1\. Find the IAM role that's using the credentials:
    
    
    $ kubectl exec -it aws-cli -- aws sts get-caller-identity

The output will look similar to: 
    
    
    {
        "UserId": "AIDACKCEVSQ6C2EXAMPLE:botocore-session-1111122222",
        "Account": "111122223333",
        "Arn": "arn:aws:sts::111122223333:assumed-role/eksctl-EKS-LAB-addon-iamserviceaccount-defau-Role1-ASA1UEXAMPLE/botocore-session-1111122222"
    }

If you specify a namespace, append the namespace argument (-n) to all kubectl commands. Replace YOUR_NAMESPACE with your namespace. 
    
    
    $ kubectl -n YOUR_NAMESPACE exec -it aws-cli -- aws sts get-caller-identity

2\. Verify that your pod has **s3:ListBuckets** permissions for your S3 bucket (**YOUR_BUCKET**):
    
    
    $ kubectl exec -it aws-cli -- aws s3 ls s3://YOUR_BUCKET

**Note:** Replace **YOUR_BUCKET** with your S3 bucket.

Output:
    
    
    2021-09-28 09:59:22        269 demo-test-file

3\. Verify that your pod can't delete the S3 bucket ( **YOUR_BUCKET**):
    
    
    $ kubectl exec -it aws-cli -- aws s3 rm s3://YOUR_BUCKET/demo-test-file

**Note:** Replace **YOUR_BUCKET** with your S3 bucket.

The command returns the following "Access Denied" error because the pod doesn't have **s3:DeleteObject** permissions:
    
    
    delete failed: s3://YOUR_BUCKET/demo-test-file An error occurred (AccessDenied) when calling the DeleteObject operation: Access Denied
    command terminated with exit code 1

4\. Verify that your pod has **dynamodb:List** permissions for your DynamoDB table (**YOUR_TABLE**):
    
    
    $ kubectl exec -it aws-cli -- aws dynamodb describe-table --table-name YOUR_TABLE

**Note:** Replace **YOUR_TABLE** with your DynamoDB table.

Output:
    
    
    {
        "Table": {
            "AttributeDefinitions": [
                {
                    "AttributeName": "demo",
                    "AttributeType": "S"
                }
            ],
            "TableName": "YOUR_TABLE",
            "KeySchema": [
                {
                    "AttributeName": "demo",
                    "KeyType": "HASH"
                }
            ],
            "TableStatus": "ACTIVE",
            "CreationDateTime": "2021-09-28T10:05:53.599000+00:00",
            "ProvisionedThroughput": {
                "NumberOfDecreasesToday": 0,
                "ReadCapacityUnits": 5,
                "WriteCapacityUnits": 5
            },
            "TableSizeBytes": 0,
            "ItemCount": 0,
            "TableArn": "arn:aws:dynamodb:eu-west-1:000000000000:table/YOUR_TABLE",
            "TableId": "42bd1238-e042-4016-b6b2-77548939c101"
        }
    }

5\. Verify that your pod can't delete the DynamoDB table ( **YOUR_TABLE**):
    
    
    $ kubectl exec -it aws-cli -- aws dynamodb delete-table --table-name YOUR_TABLE

**Note:** Replace **YOUR_TABLE** with your DynamoDB table.

The command returns the following "Access Denied" error because the pod doesn't have **dynamodb:DeleteTable** permissions:
    
    
    An error occurred (AccessDeniedException) when calling the DeleteTable operation: User: arn:aws:sts::1111122222:assumed-role/eksctl-EKS-LAB-addon-iamserviceaccount-defau-Role1-ASA1U7NRNSEC/botocore-session-1632822777 is not authorized to perform: dynamodb:DeleteTable on resource: arn:aws:dynamodb:eu-west-1: 1111122222:table/MyTable
    command terminated with exit code 254

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
