Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-rbac-errors>

# How do I troubleshoot RBAC issues with Amazon EKS?

When I use my Amazon Elastic Kubernetes Service (Amazon EKS) cluster, I want to troubleshoot errors, such as Access Denied, Unauthorized, and Forbidden.

## Short description

AWS Identity and Access Management (IAM) provides authentication to the cluster, and relies on native Kubernetes role-based access control (RBAC) for authorization. When an IAM user or role creates an Amazon EKS cluster, the IAM entity is added to the Kubernetes RBAC authorization table with **system:masters** permissions.

To add users with administrator access to an Amazon EKS cluster, complete the following steps:

  1. Allow the required IAM console permissions for the associated IAM users so that users can perform the necessary cluster operations.
  2. Update the aws-auth ConfigMap to provide the additional IAM users with the cluster role and role bindings. For more information, see [Add IAM users or roles to your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html#aws-auth-users>).



**Note:** The aws-auth ConfigMap doesn't support wildcards. It's a best practice to use **eksctl** to edit the ConfigMap. Malformed entries can lead to lockout.

Run the following kubectl **auth can-i** command to verify that RBAC permissions are set correctly:
    
    
    kubectl auth can-i list secrets --namespace dev --as dave

When you run the kubectl command, the authentication mechanism completes the following main steps:

  * Kubectl reads context configuration from **~/.kube/config**.
  * The AWS Command Line Interface (AWS CLI) command **aws eks get-token** is run to get credentials, as defined in **.kube/config**.
  * The **k8s api** request is sent and signed with the preceding token.



**Note:** You can't modify the 15-minute expiration on the token that's obtained through **aws eks get-token**.

## Resolution

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

### Authentication issues

**Error: "The cluster is inaccessible due to the cluster creator IAM user being deleted"**

If you receive the preceding error, then you must re-create the cluster creator IAM user with the same name as the cluster. To do this, find information on the cluster admin and cluster creator.

If you created the cluster within the last 90 days, then you can search AWS CloudTrail for **CreateCluster** API calls. Cluster creator permissions are identical to **system:masters** permissions. If you have other users with **system:masters** permissions, then you aren't dependent on the cluster creator. If you previously authenticated with the Amazon EKS cluster, then you can review previous [authenticator logs](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html>) in the Amazon CloudWatch log group. Use the following CloudWatch Logs Insights query to check the cluster admin user and role details:
    
    
    fields @timestamp, @message
    | sort @timestamp desc
    | filter @logStream like /authenticator/
    | filter @message like "system:masters"

To re-create the cluster creator IAM user and role, run the following commands:

**Important:** Make sure to check all AWS CLI commands and replace all instances of **example** strings with your required values. For example, replace **EXAMPLE-USER** with your username.
    
    
    aws iam create-user --user-name <EXAMPLE-USER>
    
    
    aws iam create-role --role-name <EXAMPLE-ROLE>

**Error: "Could not be assumed because it does not exist or the trusted entity is not correct or an error occurred when calling the AssumeRole operation"**

If you receive the preceding error, then verify that the [trust policy](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-custom.html>) correctly grants assume permissions to the user. For more information, see [IAM tutorial: Delegate access across AWS accounts using IAM roles](<https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_cross-account-with-roles.html>).

To identify local users that deploy the Amazon EKS cluster by default, run the following command:
    
    
    kubectl get clusterroles -l kubernetes.io/bootstrapping=rbac-defaults

Turn off anonymous access for API actions. Anonymous users have **subject** set to **name: system:unauthenticated**. To identify anonymous users, run the following command:
    
    
    kubectl get clusterrolebindings.rbac.authorization.k8s.io -o json | jq '.items[] | select(.subjects[]?.name=="system:unauthenticated")'

For more information, see the [Amazon EKS best practices guides](<https://aws.github.io/aws-eks-best-practices/security/docs/iam/#review-and-revoke-unnecessary-anonymous-access>).

### Authorization issues

**Error: "Couldn't get current server API group list"**

To troubleshoot the preceding error, see [Unauthorized or access denied (kubectl)](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized>).

**Error: "You must be logged in to the server (Unauthorized)"**

To troubleshoot the preceding error, see [How do I resolve the error "You must be logged in to the server (Unauthorized)"?](<https://repost.aws/knowledge-center/eks-api-server-unauthorized-error>)

**Error: "You must be logged in to the server (the server has asked for the client to provide credentials)"**

The preceding error occurs when you use an IAM entity to make API calls and didn't correctly map the IAM entity. You must map the IAM entity to an Amazon EKS role in the cluster's aws-auth ConfigMap. For more information, see [Turning on IAM user and role access to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>).

**Error: "Can't describe cluster control plane: AccessDeniedException"**

The preceding error occurs when you update the kubeconfig with a user and a role who don't have permission to perform the **eks:DescribeCluster** action.

**Error: "Current user or role does not have access to Kubernetes objects on this EKS cluster"**

For information on the preceding error, see [Resolve the Kubernetes object access error in Amazon EKS](<https://repost.aws/knowledge-center/eks-kubernetes-object-access-error>).

**Error: "Changing the cluster creator IAM to another user/role"**

After you create a cluster, you can't change the cluster creator IAM to another user because you can't configure a cluster creator IAM.

### Network issues

**Error: "Unable to connect to the server: dial tcp 172.xx.xx.xx.xx:443: i/o timeout"**

If you receive this error, then confirm that the [security groups](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html>) are permitting traffic from the sender's source IP address.

**Error: "Unable to connect to the server: x509: certificate is valid for *.example.com , example.com , not https://xxx.gr7.us-east-1.eks.amazonaws.com"**

If you receive this error, then verify that the proxy settings are correct.

### KUBECONFIG issues

**Error: "The connection to the server localhost:8080 was refused"**

The preceding error occurs when the kubeconfig file is missing. The kubeconfig file is located in **~/.kube/config** , and kubectl requires the file. This file contains cluster credentials that are required to connect to the cluster API server. If kubectl can't find this file, then it tries to connect to the default address (**localhost:8080**).

**Error: "Kubernetes configuration file is group-readable"**

The preceding error occurs when the permissions for the kubeconfig file are incorrect. To resolve this issue, run the following command:
    
    
    chmod o-r ~/.kube/config
    chmod g-r ~/.kube/config

### AWS IAM Identity Center (successor to AWS Single Sign-On) configuration issues

**Important:** Remove **/aws-reserved/sso.amazonaws.com/** from the **rolearn** URL. If you don't, then you can't authorize as a valid user.

**Assign user groups to an IAM permissions policy**

1\. Open the [IAM Identity Center console](<https://console.aws.amazon.com/singlesignon>).

2\. Choose the **AWS Accounts** tab, and then choose **AWS account** to assign users.

3\. Choose **Assign Users**.

4\. Search for the user groups, and then choose **Next: Permission sets**.

5\. Choose **Create new permission set** , and then choose **Create a custom permission set**.

6\. Give the permission set a name, and then select the **Create a custom permissions policy** check box.

7\. Copy the following permissions policy, and then paste it into the window:
    
    
    {
    "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "sts:AssumeRole",
          "Resource": "*"
        }
      ]
    }

8\. Choose **Create**.

**Configure role permissions with Kubernetes RBAC**

To configure role permissions with Kubernetes RBAC, use the following manifest to create a RBAC role:
    
    
    apiVersion: rbac.authorization.k8s.io/v1 
    kind: Role
    metadata:
        name: <example name of the RBAC group>
        namespace: <example name of namespace>
     rules:
     - apiGroups: [""]
        resources: ["services", "endpoints", "pods", "deployments", "ingress"]
        verbs: ["get", "list", "watch"]

**Modify the IAM authenticator ConfigMap**

1\. Run the following command to capture the IAM role of the IAM Identity Center user group that contains the desired user's data:
    
    
    aws iam list-roles | grep Arn

2\. Run the following **h** command to modify the authenticator ConfigMap:
    
    
    kubectl edit configmap aws-auth --namespace kube-system

3\. Add the following attributes to the ConfigMap under **mapRoles** :
    
    
    - rolearn: <example arn of the AWS SSO IAM role> 
    username: <example preferred username> 
    groups:
        - <example name of the RBAC group>

**Important:** Remove **/aws-reserved/sso.amazonaws.com/** from the **rolearn** URL. If you don't, then you can't authorize as a valid user.

4\. Update your kubeconfig file by running the following command:
    
    
    aws eks update-kubeconfig —-name <example eks cluster>  —-region <example region>

5\. Log in with the IAM Identity Center user name, and then run the **kubectl** commands.

* * *

## Related information

[Default roles and role bindings](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings>) [Controlling access to EKS clusters](<https://aws.github.io/aws-eks-best-practices/security/docs/iam/#controlling-access-to-eks-clusters>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
