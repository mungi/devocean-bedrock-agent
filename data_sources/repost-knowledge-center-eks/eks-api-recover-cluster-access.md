Original URL: <https://repost.aws/knowledge-center/eks-api-recover-cluster-access>

# How can I use the Amazon EKS access entry API to recover access to an EKS cluster?

Because of a single sign-on user change or an aws-auth ConfigMap deletion or corruption, I can’t access my Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

If you lose access to your EKS cluster, then you see an error similar to the following when you run kubectl commands:

"error: You must be logged in to the server (Unauthorized)."

To regain access to your cluster, use [access entries](<https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html>) to manage the permissions of the AWS Identity and Access Management (IAM) principals. You do this from outside your Amazon EKS cluster.

**Note:** If the EKS cluster creator exists, then [assume the IAM principal](<https://repost.aws/knowledge-center/iam-assume-role-cli>) of the EKS cluster creator to log in and access the cluster. By default, the EKS cluster creator is the administrator of the cluster. The following process creates an administrator role that coexists with the original IAM role of the cluster creator.

## Resolution

**Prerequisites:**

  * Install [kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>).
  * Install and [configure](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html>) the latest version of the AWS Command Line Interface (AWS CLI).
  * You have an IAM role with the following permissions: CreateAccessEntry, ListAccessEntries, DescribeAccessEntry, DeleteAccessEntry, and UpdateAccessEntry.



**Note:** If you receive errors when you run AWS CLI commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

### Use the aws eks access entry API to manage Amazon EKS cluster access

**Note:** In the following commands, replace the following:  
Replace **< ACCOUNT_ID>** with the account ID of the source account where the EKS cluster exists.  
Replace **< REGION>** with the name of your AWS Region.  
Replace **< CLUSTER_NAME>** with the name of your EKS cluster.  
Replace **< IAM_PRINCIPAL_ARN>** with the ARN of the role that you want to have administrator rights.

To use an aws eks access entry API to manage Amazon EKS cluster access, complete the following steps:

  1. In the host machine that has **kubectl** installed, [assume the IAM role](<https://repost.aws/knowledge-center/iam-assume-role-cli>) with the following permissions:
    
        {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "eks:ListAccessEntries",
                    "eks:CreateAccessEntry",
                    "eks:DescribeCluster",
                    "eks:UpdateClusterConfig"
                ],
                "Resource": [
                     "arn:aws:eks:<REGION>:<ACCOUNT_ID>:cluster/<CLUSTER_NAME>"
               ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "eks:DeleteAccessEntry",
                    "eks:ListAssociatedAccessPolicies",
                    "eks:DisassociateAccessPolicy",
                    "eks:AssociateAccessPolicy",
                    "eks:UpdateAccessEntry",
                    "eks:DescribeAccessEntry"
                ],
                "Resource": [
                     "arn:aws:eks:<REGION>:<ACCOUNT_ID>:access-entry/<CLUSTER_NAME>/*"
               ]
            }
        ]
    }

  2. To confirm your identity, run the following command:
    
        aws sts get-caller-identity

In the output of the command, note the ARN. It looks similar to the following example: **arn:aws:iam:: <ACCOUNT_ID>:user/new-cluster-admin**

  3. Run the following command to validate the Amazon EKS cluster's current authentication mode:
    
        aws eks describe-cluster --name <CLUSTER_NAME>  --query 'cluster.accessConfig.authenticationMode' --region <REGION>

If the Amazon EKS cluster's current authentication mode is **API_AND_CONFIG_MAP** , then the cluster already has the required access mode. Skip to step 5.

  4. Run the following command to update the Amazon EKS cluster's authentication mode:
    
        aws eks update-cluster-config --name <CLUSTER_NAME> --access-config authenticationMode=API_AND_CONFIG_MAP --region <REGION>

**Note:** You can switch from a **CONFIG_MAP** authentication mode to an API mode, but you can't switch from an API mode back to CONFIG_MAP mode.

  5. Run the following command to create access entry for your cluster and IAM role:
    
        aws eks create-access-entry --cluster-name <CLUSTER_NAME> --principal-arn <IAM_PRINCIPAL_ARN> --region <REGION>

The output looks similar to the following:
    
        {
        "accessEntry": {
            "clusterName": "<CLUSTER_NAME>",
            "principalArn": "arn:aws:iam::<ACCOUNT_ID>:user/new-cluster-admin",
            "kubernetesGroups": [],
            "accessEntryArn": "arn:aws:eks:<REGION>:<ACCOUNT_ID>:access-entry/<CLUSTER_NAME>/user/<ACCOUNT_ID>/new-cluster-admin/26c6d1f8-4211-3fe0-f9d2-734b912dcd9a",
            "createdAt": "2024-02-13T19:27:45.370000+00:00",
            "modifiedAt": "2024-02-13T19:27:45.370000+00:00",
            "tags": {},
            "username": "arn:aws:iam::<ACCOUNT_ID>:user/new-cluster-admin",
            "type": "STANDARD"
        }
    }

  6. Run the following command to associate the **AmazonEKSClusterAdminPolicy** to the Amazon EKS cluster and IAM role:
    
        aws eks associate-access-policy --cluster-name <CLUSTER_NAME> \
      --principal-arn <IAM_PRINCIPAL_ARN> \
      --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
      --access-scope type=cluster \
      --region <REGION>

The output looks similar to the following:
    
        {
        "accessEntry": {
            "clusterName": "<CLUSTER_NAME>",
            "principalArn": "arn:aws:iam::<ACCOUNT_ID>:user/new-cluster-admin",
            "kubernetesGroups": [],
            "accessEntryArn": "arn:aws:eks:<REGION>:<ACCOUNT_ID>:access-entry/<cluster_name>/user/<ACCOUNT_ID>/new-cluster-admin/7ec6efb3-31c8-edcf-3039-ca2b38e0d708",
            "createdAt": "2024-02-25T08:34:06.002000+00:00",
            "modifiedAt": "2024-02-25T08:34:06.002000+00:00",
            "tags": {},
            "username": "arn:aws:iam::<ACCOUNT_ID>:user/new-cluster-admin",
            "type": "STANDARD"
        }
    }

  7. To update or generate the **kubeconfig** file, run the following command to connect to the EKS cluster:
    
        aws eks update-kubeconfig --name <CLUSTER_NAME> --region <REGION>

  8. Run the following command to verify that the user can access the EKS cluster as an administrator:
    
        kubectl auth can-i '*' '*'  --all-namespaces




**Note:** If you can access the EKS cluster as an administrator, then the output displays **yes**.

## Related information

[A deep dive into simplified Amazon EKS access management controls](<https://aws.amazon.com/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/>)

[How do I resolve the error "You must be logged in to the server (Unauthorized)" when I connect to the Amazon EKS API server?](<https://repost.aws/knowledge-center/eks-api-server-unauthorized-error>)

[EKS access entries](<https://eksctl.io/usage/access-entries/>) on the eksctl website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
