Original URL: <https://repost.aws/knowledge-center/eks-kubernetes-object-access-error>

# How do I resolve the "Your current user or role does not have access to Kubernetes objects on this EKS cluster" error in Amazon EKS?

I receive the following error in Amazon Elastic Kubernetes Service (Amazon EKS): "Your current user or role does not have access to Kubernetes objects on this EKS cluster."

## Short description

You might receive this error when you use the AWS Management Console with an AWS Identity and Access Management (IAM) identity (user or role). The error indicates that the IAM user or role lacks the required RBAC permissions to access the Kubernetes API. To view Kubernetes resources on the AWS Management Console, your AWS IAM identity must map to the **aws-auth** ConfigMap in your Amazon EKS cluster. For more information, see [Using RBAC authorization](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>) on the Kubernetes website.

When you create an Amazon EKS cluster, your IAM identity is automatically granted **system:masters** permissions in the cluster's RBAC configuration. This lets you view Kubernetes resources through the Amazon EKS console. It also lets you edit the **aws-auth** ConfigMap within Kubernetes, and grant additional AWS users or roles the ability to interact with the cluster. The AWS Management Console uses IAM to authorize, and the EKS cluster uses the Kubernetes RBAC system. Because the cluster's **aws-auth** ConfigMap associates IAM identities with cluster RBAC identities, the **aws-auth** ConfigMap associates IAM identities with Kubernetes identities.

## Resolution

**Prerequisites**

Based on your situation, collect the following information.

**Non-admin user or role**

If you aren't a cluster admin IAM user or role and require visibility on the Amazon EKS console, then complete the following steps:

  1. Get the IAM Identity ARN of the AWS Management Console user. AWS IAM Authenticator doesn't allow a path in the role ARN that's used in the ConfigMap. If it's an IAM role, then use the following ARN format:  
**arn:aws:iam::111122223333:role/example**  
**Note:** Don't use the following format because it contains unnecessary information:  
**arn:aws:iam::111122223333:role/my-team/developers/example**
  2. Provide the ARN to your cluster admin, and then request that the admin add you to the **aws-auth** ConfigMap.  
**Note:** See the **Identify the IAM identity ARN of the AWS Management Console user** section for steps on how to access your ARN.



**Cluster creator or cluster admin user or role**

If you're the cluster creator or cluster admin, then use the kubectl tool or the eksctl tool to manage the **aws-auth** ConfigMap.

**Note:** By default, the **system:masters** group is bound to the **clusterrole** that's named **cluster-admin**. This **clusterrole** uses the wildcard("*") for Resources and Verbs in its **PolicyRule**. This means that any user that's assigned to the **system:masters** group has full access to all the Kubernetes resources within the cluster.

See the **Identify the cluster creator** section for steps on how cluster creators and cluster admins can identify their admin status.

### Identify the IAM Identity ARN of the AWS Management Console user

Identify the IAM user or role that you use to access the console. This IAM identity might be different from the identity that you use with the AWS Command Line Interface (AWS CLI). Confirm that the IAM user or role has [permissions](<https://docs.aws.amazon.com/eks/latest/userguide/security_iam_id-based-policy-examples.html#security_iam_id-based-policy-examples-view-own-permissions>) to view nodes and workloads for all clusters in the AWS Management Console. Then, use one of the following options to access the ARN.

**Note:** If you receive errors when you run AWS CLI commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

**AWS CLI**

If you have AWS CLI access to the IAM user or role, then run the following command:
    
    
    aws sts get-caller-identity --query Arn

**CloudShell**

If you don't have AWS CLI access, then run the following command from AWS CloudShell:
    
    
    aws sts get-caller-identity --query Arn

The output is similar to the following:
    
    
    "arn:aws:iam::111122223333:role/testrole"

-or-
    
    
    "arn:aws:iam::111122223333:user/testuser"

**Note:**

  * If it's an IAM role ARN, then make sure that the format is similar to the ARN format from the **Prerequisites** section.
  * If the ARN includes **assumed-role** , then you must get the ARN of the role. For example, the assumed role ARN of **arn:aws:sts::123456:assumed-role/MyRole/aadams** is associated with the role ARN **arn:aws:sts::123456:role/MyRole**. Verify this value in the IAM console.



### Identify the cluster creator

To find the cluster creator or admin role with primary permissions to configure your cluster, search for the [CreateCluster](<https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateCluster.html>) API call in AWS CloudTrail. Then, check the **userIdentity** section of the API call. If you find the cluster creator name in CloudTrail but it's deleted, then recreate a new IAM user or role with the same name. Because this new IAM identity has the same ARN as the original cluster creator, it inherits the same admin access to the cluster.

**Note:** CloudTrail provides only 90 days of history.

### Add the new IAM user or role to the Kubernetes RBAC

To add the new IAM user or role to the Kubernetes RBAC, first configure the AWS CLI to use the cluster creator IAM. To verify that the AWS CLI is correctly configured with the IAM identity, run the following command:
    
    
    $ aws sts get-caller-identity

The output returns the ARN of the IAM user or role. For example:
    
    
    {
        "UserId": "XXXXXXXXXXXXXXXXXXXXX",
        "Account": "XXXXXXXXXXXX",
        "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/testuser"
    }

Then, use kubectl or eksctl to modify the **aws-auth** ConfigMap.

**kubectl**

  1. To use kubectl to modify the **aws-auth** ConfigMap, run the following kubectl command to have access to the cluster:
    
        $ kubectl edit configmap aws-auth -n kube-system

The console shows the current ConfigMap. If you can't connect to the cluster, then update your kubeconfig file. Because the identity that creates the cluster always has cluster access, run the command with an IAM identity that has access to the cluster:
    
        aws eks update-kubeconfig --region region_code --name my_cluster

**Note:** Replace **region_code** with your EKS cluster AWS Region code and **my_cluster** with your EKS cluster name.  
The kubectl commands must connect to the EKS server endpoint. If the API server endpoint is public, then you must have internet access to connect to the endpoint. If the API server endpoint is private, then connect to the EKS server endpoint from within the virtual private cloud (VPC) where the EKS cluster is running.

  2. To edit the **aws-auth** ConfigMap in the text editor as the cluster creator or admin, run the following command:
    
        $ kubectl edit configmap aws-auth -n kube-system

  3. Add an IAM user or role:
    
        mapUsers: |
      - userarn: arn:aws:iam::XXXXXXXXXXXX:user/testuser
        username: testuser
        groups:
        - system:bootstrappers
        - system:nodes

Or, add the IAM role to **mapRoles**. For example:
    
        mapRoles: |
      - rolearn: arn:aws:iam::XXXXXXXXXXXX:role/testrole
        username: testrole
        groups:
        - system:bootstrappers
        - system:nodes




It's a best practice not to use **system:masters** for production environments because **system:masters** allows a superuser access to perform any action on any resource. Also, it's a best practice to minimize granted permissions. Create a role with access to only a specific namespace. Review the **View Kubernetes resources in a specific namespace** section of [Required permissions](<https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions>).

**eksctl**

To use the eksctl tool to update the **aws-auth** ConfigMap, run the following command:
    
    
    eksctl create iamidentitymapping --cluster your_cluster_Name --region=your_region --arn YOUR_IAM_ARN <arn:aws:iam::123456:role testing=""> --group system:masters --username admin</arn:aws:iam::123456:role>

**Note:** Replace **your_cluster_Name** with your EKS cluster name, **your_region** with your EKS cluster Region, and **YOUR_IAM_ARN** with your IAM role or use ARN.

### Verify access to your Amazon EKS cluster

Complete the following steps:

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>).
  2. In the navigation pane, choose **Clusters**.
  3. Choose your cluster.
  4. Check the **Overview** and **Workloads** tabs for errors.



If you configured for a specific namespace, then you see the following error message in the Amazon EKS console:

"Error loading Deploymentsdeployments.apps is forbidden: User "xxxxxx" cannot list resource "deployments" in API group "apps" at the cluster scope or in the namespace "xxxxxxx"

The error doesn't appear for the specific namespace. To troubleshoot error messages, see [Can't see Nodes on the Compute tab or anything on the Resources tab and you receive an error in the AWS Management Console](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting_iam.html#security-iam-troubleshoot-cannot-view-nodes-or-workloads>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
