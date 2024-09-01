Original URL: <https://repost.aws/knowledge-center/eks-load-balancer-webidentityerr>

# Why do I get the "WebIdentityErr" error when I use AWS Load Balancer Controller in Amazon EKS?

When I try to use the AWS Load Balancer Controller in Amazon Elastic Kubernetes Service (Amazon EKS), I get a "WebIdentityErr" error message.

## Short description

When you use the AWS Load Balancer Controller in Amazon EKS, you might see the following error:

"failed to find existing LoadBalancer due to WebIdentityErr: failed to retrieve credentials\ncaused by: AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity\n\tstatus code: 403"

The error occurs for the following reasons:

  * Incorrect service account configurations
  * Incorrect trust relationship of the AWS Identity and Access Management (IAM) role that you use in the service account



When you use the AWS Load Balancer Controller, worker nodes perform the tasks. You must use IAM permissions to grant these worker nodes access to the Application Load Balancer or Network Load Balancer resources. To set up the IAM permissions, use IAM roles for the service account. Or, attach the IAM permissions directly to the worker node's IAM roles. For more information, see [AWS Load Balancer Controller installation](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/deploy/installation/>) on the Kubernetes website.

## Resolution

### Incorrect service account configurations

To check if you correctly configured your service account, complete the following steps:

  1. Verify the service account name that's defined in your deployment:
    
        kubectl describe deploy aws-load-balancer-controller -n kube-system | grep -i "Service Account"

  2. Describe the service account:
    
        kubectl describe sa aws-load-balancer-controller -n kube-system

  3. Verify the service account annotation for the IAM role:
    
        Annotations: eks.amazonaws.com/role-arn:arn:aws:iam::xxxxxxxxxx:role/ AMAZON_EKS_LOAD_BALANCER_CONTROLLER_ROLE

  4. If the annotation is missing or incorrect, then update the annotation. Make sure that you correctly [associated the IAM role to a service account](<https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html>):
    
        kubectl annotate serviceaccount -n SERVICE_ACCOUNT_NAMESPACE SERVICE_ACCOUNT_NAME \ eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT_ID:role/IAM_ROLE_NAME

  5. Restart the AWS Load Balancer Controller deployment to refresh the pods credentials.
    
        kubectl rollout restart deployment/aws-load-balancer-controller -n kube-system




### Incorrect trust relationship between the IAM role used and service account

When you establish the trust relationship between your IAM role and service account, you might encounter issues. Review the following examples of common mistakes that occur when you establish the trust relationship.

**IAM role or trust relationship isn't correctly defined for the "sts:AssumeRoleWithWebIdentity" action**

Verify that the trust relationship is correctly defined for the **sts:AssumeRoleWithWebIdentity** action and not the **sts:AssumeRole** action.

The following example is a trust relationship that isn't correctly defined:
    
    
    {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "Service": "xxxxx.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
    }

To resolve this issue, define the trust relationship for the **sts:AssumeRoleWithWebIdentity** action:
    
    
    {
      "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_OIDC-PROVIDER_ID"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
              "StringEquals": {
                "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_OIDC_PROVIDER_ID:sub": "system:serviceaccount:kube-system:LOAD_BALANCER_CONTROLLER_SERVICE_ACCOUNT",
                "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_OIDC_PROVIDER_ID:aud": "sts.amazonaws.com"
              }
            }
          }
        ]
      }

**Note:** Replace all variables with your own values.

To use the same IAM role for multiple clusters in one account, define the trust relationship:
    
    
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::AWS-ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_1_OIDC-PROVIDER_ID"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_1_OIDC_PROVIDER_ID:sub": "system:serviceaccount: kube-system:LOAD_BALANCER_CONTROLLER_SERVICE_ACCOUNT",
              "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_1_OIDC_PROVIDER_ID:aud": "sts.amazonaws.com"
            }
          }
        },
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::AWS_ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_2_OIDC_PROVIDER_ID"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_2_OIDC_PROVIDER_ID:sub": "system:serviceaccount: kube-system:LOAD_BALANCER_CONTROLLER_SERVICE_ACCOUNT",
              "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_2_OIDC_PROVIDER_ID:aud": "sts.amazonaws.com"
            }
          }
        }
      ]
    }

**Incorrect OIDC provider ID when you create an Amazon EKS cluster**

[Create and verify an OpenID Connect (OIDC) provider for your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>). Verify that the OIDC provider ID and the associated AWS Region are correctly listed. Otherwise, you receive a **WebIdentityErr** error.

**Service account name or its namespace not correctly entered**

Review your AWS Load Balancer Controller deployment. When you update your deployment, make sure to enter the correct service account name and its namespace.

**Missing "sts.amazonaws.com" steps from the trust relationship**

If the service role that's associated with your EKS pod can't perform the STS operation on the **AssumeRoleWithWebIdentity** action, then update the trust relationship. To perform an STS operation, the trust relationship must include **sts.amazonaws.com** :
    
    
    "Condition": {
            "StringEquals": {
              "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_1_OIDC_PROVIDER_ID:sub": "system:serviceaccount:kube-system:LOAD_BALANCER_CONTROLLER_ACCOUNT",
              "oidc.eks.REGION.amazonaws.com/id/EKS_CLUSTER_1_OIDC_PROVIDER_ID:aud": "sts.amazonaws.com"
            }
    }

For more information about IAM conditions with multiple keys or values, see [Conditions with multiple context keys or values](<https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_multi-value-conditions.html>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
