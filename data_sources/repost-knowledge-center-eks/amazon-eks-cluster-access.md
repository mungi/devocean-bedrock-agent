Original URL: <https://repost.aws/knowledge-center/amazon-eks-cluster-access>

# How do I provide access to other IAM users and roles after cluster creation in Amazon EKS?

When I try to access the Amazon Elastic Kubernetes Service (Amazon EKS) cluster through kubectl commands, I get the following authorization error: "error: You must be logged in to the server (Unauthorized)."

## Short description

You get an authorization error when your AWS Identity and Access Management (IAM) entity isn't authorized by the [role-based access control (RBAC)](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>) configuration of the Amazon EKS cluster. This happens when an IAM user or role creates an Amazon EKS cluster that's different from the one used by **aws-iam-authenticator**.

Initially, only the creator of the Amazon EKS cluster has [system:masters permissions](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>) to configure the cluster. To extend **system:masters** permissions to other users and roles, you must add the **aws-auth** **ConfigMap** to the configuration of the Amazon EKS cluster. The **ConfigMap** allows other IAM entities, such as users and roles, to access the Amazon EKS cluster.

To [grant access to an IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>), you must assume the cluster creator credentials. Then, add the IAM role in the **mapRoles** section of the **aws-auth** **ConfigMap**.

**Important:**

  * Avoid syntax errors, such as typos, when you update the **aws-auth** **ConfigMap**. These errors can affect the permissions of all IAM users and roles that are updated within the **ConfigMap** of the Amazon EKS cluster.
  * It's a best practice to avoid adding **cluster_creator** to the **ConfigMap**. Improperly modifying the **ConfigMap** can cause all IAM users and roles, including **cluster_creator** , to permanently lose access to the Amazon EKS cluster.
  * You don't need to add **cluster_creator** to the **aws-auth ConfigMap** to get admin access to the Amazon EKS cluster. By default, the **cluster_creator** has admin access to the Amazon EKS cluster that it created.



**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you're using the most recent version of the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

## Resolution

**Note:** In the following steps, the cluster creator is **cluster_creator**. The user that doesn't currently have access to the cluster but needs access is **designated_user**.

### Identify the IAM user or role for the cluster creator

1\. Identify the IAM user or role for the cluster creator that has primary access to configure your Amazon EKS cluster.

2\. Identify the IAM user that the cluster creator grants authorization to after cluster creation. To identify the cluster creator, search for the [CreateCluster](<https://docs.aws.amazon.com/eks/latest/APIReference/API_CreateCluster.html>) API call in AWS CloudTrail, and then check the **userIdentity** section of the API call.

### Add designated_user to the ConfigMap if cluster_creator is an IAM user

1\. [Install kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>) on your local host machine. Or, if you have a dedicated Amazon Elastic Compute Cloud (Amazon EC2) instance with a **kubectl** package installed, use SSH to connect to the instance.

2\. On the same host machine where **kubectl** is installed, configure the AWS CLI with the **designated_user** credentials:
    
    
    aws configure

3\. In the AWS CLI, run the following command:
    
    
    aws sts get-caller-identity

The output should return the IAM user details for **designated_user**.

For example:
    
    
    {
        "UserId": "XXXXXXXXXXXXXXXXXXXXX",
        "Account": "XXXXXXXXXXXX",
        "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/designated_user"
    }

4\. List the pods that are running in the cluster of the default namespace:
    
    
    kubectl get pods --namespace default

The output shows the following: "error: You must be logged in to the server (Unauthorized)." This error means that **designated_user** doesn't have authorization to access the Amazon EKS cluster.

5\. Configure the AWS access key ID and the AWS secret access key of **cluster_creator**.

If the cluster was created using the AWS Management Console, then identify the IAM role or user that created the cluster. In the host machine where **kubectl** is installed, configure the **cluster_creator** IAM user or role in the AWS CLI:
    
    
    aws configure

If **eksctl** was used to create the cluster, then use the default or specified AWS CLI profile credentials to configure the AWS CLI to run **kubectl** commands.

6\. Verify that **cluster_creator** has access to the cluster:
    
    
    kubectl get pods

If everything is set up correctly, then you don't get an unauthorized error message. The output should list all the pods that are running in the default namespace. If the output shows that no resources are found, then no pods are running in the default namespace.

7\. To give **designated_user** access to the cluster, add the **mapUsers** section to your **aws-auth.yaml** file. See the example **aws-auth.yaml** file from [Enabling IAM user and role access to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>).

8\. Add **designated_user** to the **mapUsers** section of the **aws-auth.yaml** file in step 7, and then save the file.

9\. Apply the new **ConfigMap** to the RBAC configuration of the cluster:
    
    
    kubectl apply -f aws-auth.yaml

10\. Change the AWS CLI configuration again to use the credentials of **designated_user** :
    
    
    aws configure

11\. Verify that **designated_user** has access to the cluster:
    
    
    kubectl get pods

If everything is set up correctly, you don't get an unauthorized error message. The output lists all the pods that are running in the default namespace. If the output shows that no resources are found, then no pods are running in the default namespace.

### Add designated_user to the ConfigMap if the cluster_creator is an IAM role

In the preceding steps, you used the **cluster_creator** credentials to provide access to **designated_user**. However, if an IAM role created the cluster instead of an IAM user, then there are no credentials that you can use. In this case, you must assume the IAM role that created the cluster to provide access to **designated_user**. If the cluster creator isn't an IAM role, then you don't need to complete the following steps.

**Note:** In the following steps, **assume_role_user** is the user who assumes the **cluster_creator** role. The user that doesn't currently have access to the cluster but needs access is **designated_user**.

To assume the IAM role and edit the **aws-auth** **ConfigMap** on the cluster so that you can provide access to **designated_user** , complete the following steps:

1\. Show the IAM user details of **assume_role_user** :
    
    
    aws sts get-caller-identity

2\. Confirm that **assume_role_user** has access to the cluster:
    
    
    kubectl get pods

The output shows the following error: "error: You must be logged in to the server (Unauthorized)." This error means that the **assume_role_user** doesn't have authorization to configure the Amazon EKS cluster.

3\. Allow **assume_role_user** to assume the role of **cluster_creator** :
    
    
    aws sts assume-role --role-arn arn:aws:iam:11122223333:role/cluster_creator --role-session-name test

The output shows the temporary IAM credentials for **assume_role_user**.

4\. Use the temporary IAM credentials to set the **AWS_ACCESS_KEY_ID** , **AWS_SESSION_TOKEN** , and **AWS_SECRET_ACCESS_KEY** environment variables.

For example:
    
    
    export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
    export AWS_SESSION_TOKEN=EXAMPLETOKEN
    export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

The AWS CLI now ranks the credentials that are set in the environment variables and uses them to make calls to AWS services.

5\. Verify that the AWS CLI is using the assumed role for **cluster_creator** :
    
    
    aws sts get-caller-identity

6\. To give **designated_user** access to the cluster, add the **mapUsers** section to your **aws-auth.yaml** file. See the example **aws-auth.yaml** file from [Enabling IAM user and role access to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>).

7\. Add **designated_user** to the **mapUsers** section of the **aws-auth.yaml** file in step 6, and then save the file.

8\. Apply the new configuration to the RBAC configuration of the Amazon EKS cluster:
    
    
    kubectl apply -f aws-auth.yaml

9\. Unset the following environment variables:
    
    
    unset AWS_ACCESS_KEY_ID
    unset AWS_SESSION_TOKEN
    unset AWS_SECRET_ACCESS_KEY

10\. Show the IAM user details of **designated_user** :
    
    
    aws sts get-caller-identity

11\. Confirm that **designated_user** has access to the cluster:
    
    
    kubectl get pods

If everything is set up correctly, then you don't get an unauthorized error message. The output lists all the pods that are running in the default namespace. If the output shows that no resources are found, then no pods are running in the default namespace.

**Note:** If you use **eksctl** , then consider the resolution at [Manage IAM users and roles](<https://eksctl.io/usage/iam-identity-mappings/#manage-iam-users-and-roles>) on the Weaveworks website.

* * *

## Related information

[Using an IAM role in the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
