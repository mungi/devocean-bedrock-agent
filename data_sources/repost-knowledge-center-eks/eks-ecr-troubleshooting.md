Original URL: <https://repost.aws/knowledge-center/eks-ecr-troubleshooting>

# How do I troubleshoot Amazon ECR issues with Amazon EKS?

I can't pull images from Amazon Elastic Container Registry (Amazon ECR) when I use Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

You can't pull images from Amazon ECR for one of the following reasons:

  * You can't communicate with Amazon ECR endpoints.
  * You don't have the appropriate permissions in your worker node's node instance role.
  * You haven't created interface VPC endpoints.



Based on your use case, use one or more of the following resolution sections.

## Resolution

### Troubleshoot communication between worker nodes and Amazon ECR endpoints

If your worker nodes can't communicate with the Amazon ECR endpoints, then you see this error message:
    
    
    Failed to pull image "ACCOUNT.dkr.ecr.REGION.amazonaws.com/imagename:tag": rpc error: code = Unknown desc = 
    Error response from daemon: Get https://ACCOUNT.dkr.ecr.REGION.amazonaws.com/v2/: net/http: 
    request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)

To resolve this error, confirm the following:

  * The subnet for your worker node has a route to the internet. Check the [route table](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html>) associated with your subnet.
  * The security group associated with your worker node allows outbound internet traffic.
  * The ingress and egress rule for your network access control lists (ACLs) allows access to the internet.



### Update the instance IAM role of your worker nodes

In the following example, your worker node's instance AWS Identity and Access Management (IAM) role doesn't have the required permission to pull images from Amazon ECR. In this case, you get the following error from your Amazon EKS pod:
    
    
    Warning  Failed     14s (x2 over 28s)  kubelet, ip-000-000-000-000.us-west-2.compute.internal  Failed to pull image "ACCOUNT.dkr.ecr.REGION.amazonaws.com/imagename:tag": rpc error: code = Unknown desc = Error response from daemon: Get https://ACCOUNT.dkr.ecr.REGION.amazonaws.com/v2/imagename/manifests/tag: no basic auth credentialsWarning  Failed     14s (x2 over 28s)  kubelet, ip-000-000-000-000.us-west-2.compute.internal  Error: ErrImagePull
    Normal   BackOff    2s (x2 over 28s)   kubelet, ip-000-000-000-000.us-west-2.compute.internal  Back-off pulling image "ACCOUNT.dkr.ecr.REGION.amazonaws.com/imagename:tag"
    Warning  Failed     2s (x2 over 28s)   kubelet, ip-000-000-000-000.us-west-2.compute.internal  Error: ImagePullBackOff

To resolve this error, confirm that your worker nodes use the [AmazonEC2ContainerRegistryReadOnly](<https://docs.aws.amazon.com/AmazonECR/latest/userguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerRegistryReadOnly>) AWS Identity and Access Management (IAM) managed policy. Or, [update the Amazon Elastic Compute Cloud (Amazon EC2) instance profile](<https://repost.aws/knowledge-center/attach-replace-ec2-instance-profile>) of your worker nodes with the following IAM permissions:
    
    
    "ecr:GetAuthorizationToken",
    "ecr:BatchCheckLayerAvailability",
    "ecr:GetDownloadUrlForLayer",
    "ecr:GetRepositoryPolicy",
    "ecr:DescribeRepositories",
    "ecr:ListImages",
    "ecr:DescribeImages",
    "ecr:BatchGetImage",
    "ecr:GetLifecyclePolicy",
    "ecr:GetLifecyclePolicyPreview",
    "ecr:ListTagsForResource",
    "ecr:DescribeImageScanFindings"

**Important:** It's a best practice to use the **AmazonEC2ContainerRegistryReadOnly** policy. Don't create a duplicate policy.

The updated instance IAM role gives your worker nodes the permission to access Amazon ECR and pull images through the kubelet. The kubelet is fetches and periodically refreshes Amazon ECR credentials. For more information, see [Images](<https://kubernetes.io/docs/concepts/containers/images/>) on the Kubernetes website.

### Confirm that your repository policies are correct

[Repository policies](<https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html>) are a subset of IAM policies that control access to individual Amazon ECR repositories. IAM policies generally apply permissions for the entire Amazon ECR service, but they can also control access to specific resources.

  1. Open the [Amazon ECR console](<https://console.aws.amazon.com/ecr/>) for your primary account.
  2. Navigate to the AWS Region that contains the ECR repository.
  3. On the navigation pane, choose **Repositories**. Then, choose the repository that you want to check.
  4. On the navigation pane, choose **Permissions**. Then, check if your repository has the correct permissions.  
This example policy allows a specific IAM user to describe the repository and the images within the repository:
    
        {  
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "ECR Repository Policy",
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::123456789012:user/MyUsername"
          },
          "Action": [
            "ecr:DescribeImages",
            "ecr:DescribeRepositories"
          ]
        }
      ]
    }




### Confirm that your repository policies allow access if your EKS is in different AWS account

If you don't have access to container images in another AWS account, then the kubelet fails with the following error:
    
    
    Failed to pull image "cross-aws-account-id:.dkr.ecr.REGION.amazonaws.com/repo-name:image-tag": rpc error: code = Unknown desc = Error response from daemon: pull access denied for arn:aws:ecr:REGION:cross-aws-account-id:repository/repo-name, repository does not exist or may require 'docker login': denied: User: arn:aws:sts::<aws-account-containing-eks-cluster>:assumed-role/<node-instance-role-for-worker-node is not authorized to perform: ecr:BatchGetImage on resource: arn:aws:ecr:REGION:cross-aws-account-id:repository/repo-name

The following example policy allows the instance IAM role in one AWS account to describe and pull container images from an ECR repository in another AWS account:
    
    
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::123456789012:role/eksctl-cross-account-ecr-access-n-NodeInstanceRole"
          },
          "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:ListTagsForResource",
            "ecr:DescribeImageScanFindings"
          ],
          "Resource": "*"
        }
      ]
    }

**Note:** Use the ARN of the instance IAM role in the ECR policy, not instance profile ARN.

### Create interface VPC endpoints

To pull images from Amazon ECR, you must [configure interface VPC endpoints](<https://docs.aws.amazon.com/vpc/latest/privatelink/interface-endpoints.html>). See [Creating the VPC Endpoints for Amazon ECS](<https://docs.aws.amazon.com/AmazonECS/latest/developerguide/vpc-endpoints.html#ecs-setting-up-vpc-create>).

### Confirm that your Fargate pod execution role is configured correctly

If your Fargate CoreDNS pod is stuck in the **ImagePullBackOff** state when you retrieve images from Amazon hosted repositories, then you see this error message:
    
    
    Warning   Failed           27s (x2 over 40s)  kubelet            Failed to pull image "151284513677.dkr.ecr.eu-central-1.amazonaws.com/coredns:latest ": rpc error: code = Unknown desc = failed to pull and unpack image "151284513677.dkr.ecr.eu-central-1.amazonaws.com/coredns:latest ": failed to resolve reference "151284513677.dkr.ecr.eu-central-1.amazonaws.com/coredns:latest ": pulling from host 151284513677.dkr.ecr.eu-central-1.amazonaws.com failed with status code [manifests latest]: 401 Unauthorized

To troubleshoot this error, be sure that you set up the Fargate pod execution role to use the [AmazonEKSFargatePodExecutionRolePolicy](<https://console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy%24jsonEditor>). Be sure that a trust policy that's similar to the following is attached to the role:
    
    
    {  
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::123456789012:role/eksctl-cross-account-ecr-access-n-NodeInstanceRole"
          },
          "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:ListTagsForResource",
            "ecr:DescribeImageScanFindings"
          ],
          "Resource": "*"
        }
      ]
    }

**Note:** Replace **example-region** with the name of your AWS Region. Replace **1111222233334444** with the account number, and **example-cluster** with the name of your cluster.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
