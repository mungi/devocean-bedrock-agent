Original URL: <https://repost.aws/knowledge-center/eks-generate-kubeconfig-file-for-cluster>

# Why can't I generate a kubeconfig file for my Amazon EKS cluster?

I get an AccessDeniedException error when I try to generate a kubeconfig file for an Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

You must have permission to use the **eks:DescribeCluster** API action with the cluster to generate a **kubeconfig** file for an Amazon EKS cluster. To get permission, attach an AWS Identity and Access Management (IAM) policy to an IAM user.

## Resolution

To attach an IAM policy to a user, complete the following steps:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>). Then, in the navigation pane, choose **Users or Roles**.

  2. Select the name of the **user or role** to embed a policy in.

  3. On the **Permissions tab** , choose **Add inline policy**.

  4. Choose the **JSON** tab.

  5. Use a text editor to replace the code with the following IAM policy:
    
        {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "eks:DescribeCluster"
          ],
          "Resource": "*"
        }
      ]
    }

  6. Choose **Review policy**.

  7. For **Name** , enter a name for the policy. For example: **eks_update-kubeconfig**.

  8. Choose **Create policy**.  
**Note** : If you have enforced multi-factor authentication (MFA) for IAM users that use the AWS Command Line Interface (AWS CLI), then before you complete the next step, you must authenticate with MFA. An **explicit deny** message indicates that if MFA is false, then there is an IAM policy that denies actions:
    
        {  "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "BlockMostAccessUnlessSignedInWithMFA",
          "Effect": "Deny",
          "NotAction": [
            "iam:CreateVirtualMFADevice",
            "iam:EnableMFADevice",
            "iam:ListMFADevices",
            "iam:ListUsers",
            "iam:ListVirtualMFADevices",
            "iam:ResyncMFADevice",
            "sts:GetSessionToken"
          ],
          "Resource": "*",
          "Condition": {
            "BoolIfExists": {
              "aws:MultiFactorAuthPresent": "false"
            }
          }
        }
      ]
    }

Because you use an MFA device, you must use an MFA token to authenticate access to AWS resources with the AWS CLI. Follow the steps in the article [How do I use an MFA token to authenticate access to my AWS resources through the AWS CLI?](<https://repost.aws/knowledge-center/authenticate-mfa-cli>) Then, run the **sts get-session-token** AWS CLI command. Replace **arn-of-the-mfa-device** with the ARN of your MFA device and **code-from-token** with your token's code:
    
        $ aws sts get-session-token --serial-number arn-of-the-mfa-device --token-code code-from-token

You can use temporary credentials by exporting the values to environment variables.

For example:
    
        $ export AWS_ACCESS_KEY_ID=example-access-key-as-in-previous-output$ export AWS_SECRET_ACCESS_KEY=example-secret-access-key-as-in-previous-output$ export AWS_SESSION_TOKEN=example-session-token-as-in-previous-output

  9. Run the **update-kubeconfig** command and confirm that it updates the config file under **~/.kube/config.** Replace **region-code** with your AWS Region's code and **cluster_name** with your cluster's name:
    
        aws eks --region region-code update-kubeconfig --name cluster_name




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
