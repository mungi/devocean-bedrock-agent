Original URL: <https://repost.aws/knowledge-center/eks-api-server-unauthorized-error>

# How do I resolve the error "You must be logged in to the server (Unauthorized)" when I connect to the Amazon EKS API server?

I'm using kubectl commands to connect to the Amazon Elastic Kubernetes Service (Amazon EKS) application programming interface (API) server. I received the message "error: You must be logged in to the server (Unauthorized)".

## Short description

You get this error when the AWS Identity and Access Management (IAM) entity that's configured in kubectl isn't authenticated by Amazon EKS.

You are authenticated and authorized to access your Amazon EKS cluster based on the IAM entity (user or role) that you use. Therefore, be sure of the following:

  * You configured kubectl tool to use your IAM user or role.
  * Your IAM entity is mapped to the aws-auth ConfigMap.



To resolve this issue, you must complete the steps in one of the following sections based on your use case:

  * You're the cluster creator
  * You're not the cluster creator



## Resolution

If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [confirm that you're running a recent version of the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html#general-latest>).

### You're the cluster creator

You're the cluster creator if your IAM entity was used to create the Amazon EKS cluster.

1\. Run the following query in Amazon CloudWatch Log Insights to identify the cluster creator ARN:

First, select the log group for your Amazon EKS cluster (example: /aws/eks/my-cluster/cluster). Then, run the following query:
    
    
    fields @logstream, @timestamp, @message
    | sort @timestamp desc
    | filter @logStream like /authenticator/
    | filter @message like "username=kubernetes-admin"
    | limit 50

**Note:** Be sure that you turned on Amazon EKS authenticator logs.

This query returns the IAM entity that's mapped as the cluster creator:
    
    
    @message
    time="2022-05-26T18:55:30Z" level=info msg="access granted" arn="arn:aws:iam::123456789000:user/testuser" client="127.0.0.1:57586" groups="[system:masters]" method=POST path=/authenticate uid="aws-iam-authenticator:123456789000:AROAFFXXXXXXXXXX" username=kubernetes-admin

2\. Be sure that you configured the AWS CLI with the cluster creator IAM entity. To see if the IAM entity is configured for AWS CLI in your shell environment, run the following command:
    
    
    $ aws sts get-caller-identity

You can also run this command using a specific profile:
    
    
    $ aws sts get-caller-identity --profile MY-PROFILE

The output returns the Amazon Resource Name (ARN) of the IAM entity that's configured for AWS CLI.

Example:
    
    
    {
        "UserId": "XXXXXXXXXXXXXXXXXXXXX",
        "Account": "XXXXXXXXXXXX",
        "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/testuser"
    }

Confirm that the IAM entity that's returned matches the cluster creator IAM entity. If the returned IAM entity isn't the cluster creator, then [update the AWS CLI configuration](<https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html>) to use the cluster creator IAM entity.

3\. Update or generate the **kubeconfig** file using the following command:
    
    
    $ aws eks update-kubeconfig --name eks-cluster-name --region aws-region

**Note:**

  * Replace **eks-cluster-name** with the name of your cluster.
  * Replace **aws-region** with the name of your AWS Region.



To specify an AWS CLI profile, run the following command:
    
    
    $ aws eks update-kubeconfig --name eks-cluster-name —region aws-region —profile my-profile

**Note:**

  * Replace **eks-cluster-name** with the name of your cluster.
  * Replace **aws-region** with the name of your Region.
  * Replace **my-profile** with the name of your profile.



4\. To confirm that the **kubeconfig** file is updated, run the following command:
    
    
    $ kubectl config view --minify

5\. To confirm that your IAM entity is authenticated and that you can access your EKS cluster, run the following command:
    
    
    $ kubectl get svc

Example output:
    
    
    NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
    kubernetes      ClusterIP   10.100.0.1     <none>        443/TCP   77d

### You're not the cluster creator

You're not the cluster creator if your IAM entity wasn't used to create the cluster. In this case, you must map your IAM entity to the aws-auth ConfigMap to allow access to the cluster.

1\. Be sure that you configured the AWS CLI with your IAM entity. To see the IAM entity that's configured for AWS CLI in your shell environment, run the following command:
    
    
    $ aws sts get-caller-identity

You can also run this command using a specific profile:
    
    
    $ aws sts get-caller-identity --profile my-profile

The output returns the ARN of the IAM entity that's configured for AWS CLI.

Example:
    
    
    {
        "UserId": "XXXXXXXXXXXXXXXXXXXXX",
        "Account": "XXXXXXXXXXXX",
        "Arn": "arn:aws:iam::XXXXXXXXXXXX:user/testuser"
    }

Confirm that the IAM entity that's returned is your IAM entity. If the returned IAM entity isn't the one used to interact with your cluster, first update the AWS CLI configuration to use the correct IAM entity. Then, retry accessing your cluster using kubectl. If the issue persists, continue to step 2.

2\. If the returned IAM entity isn't the cluster creator, add your IAM entity to the aws-auth ConfigMap. This allows the IAM entity to access the cluster.

Only the cluster admin can modify aws-auth ConfigMap. Therefore, do either of the following:

  * Use the instructions in the **You're cluster creator** section to access the cluster using the cluster creator IAM entity.
  * Ask the cluster admin to perform this action.



Check if your IAM entity is in the aws-auth ConfigMap by running the following command:
    
    
    eksctl get iamidentitymapping --cluster cluster-name

-or-
    
    
    kubectl describe configmap aws-auth -n kube-system

If your IAM entity is in the aws-auth ConfigMap, then you can skip to step 3.

Map your IAM entity automatically by running the following command:
    
    
    eksctl create iamidentitymapping \
        --cluster $CLUSTER-NAME \
        --region $REGION \
        --arn arn:aws:iam::XXXXXXXXXXXX:user/testuser \
        --group system:masters \
        --no-duplicate-arns \
        --username admin-user1

Or, you can map your IAM entity manually by editing the aws-auth ConfigMap:
    
    
    $ kubectl edit configmap aws-auth --namespace kube-system

To add an IAM user, add the IAM user ARN to **mapUsers**.

Example:
    
    
    mapUsers: |
      - userarn: arn:aws:iam::XXXXXXXXXXXX:user/testuser
        username: testuser
        groups:
          - system:masters

To add an IAM role, add the IAM role ARN to **mapRoles**.

Example:
    
    
    mapRoles: |
      - rolearn: arn:aws:iam::XXXXXXXXXXXX:role/testrole
        username: testrole
        groups:
          - system:masters

**Important:**

  * The IAM role must be mapped without the path. To learn more about **rolearn** path requirements, expand the **aws-auth ConfigMap does not grant access to the cluster section** in [Troubleshooting IAM](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting_iam.html>).
  * To specify **rolearn** for an AWS IAM Identity Center (successor to AWS Single Sign-On) IAM role, remove the path "/aws-reserved/sso.amazonaws.com/REGION" from the Role ARN. Otherwise, the entry in the ConfigMap can't authorize you as a valid user.
  * The **system:masters** group allows superuser access to perform any action on any resource. For more information, see [Default roles and role bindings](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/#default-roles-and-role-bindings>). To restrict access for this user, you can create an Amazon EKS role and role binding resource. For an example of restricted access for users viewing resources in the Amazon EKS console, follow steps 2 and 3 in [Required permissions](<https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions>).



3\. Update or generate the **kubeconfig** file by running the following command. Be sure that the AWS CLI is configured with your IAM entity that's returned in step 1.
    
    
    $ aws eks update-kubeconfig --name eks-cluster-name --region aws-region

**Note:**

  * Replace **eks-cluster-name** with the name of your cluster.
  * Replace **aws-region** with the name of your AWS Region.



You can also run this command using a specific profile:
    
    
    $ aws eks update-kubeconfig --name eks-cluster-name —region aws-region —profile my-profile

**Note:**

  * Replace **eks-cluster-name** with the name of your cluster.
  * Replace **aws-region** with the name of your AWS Region.
  * Replace **my-profile** with the name of your profile.



4\. To confirm that the **kubeconfig** file is updated, run the following command:
    
    
    $ kubectl config view --minify

5\. To confirm that your IAM user or role is authenticated, try to access the cluster again. For example, you can run the following command to confirm that the error is resolved:
    
    
    $ kubectl get svc

Example output:
    
    
    NAME            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
    kubernetes      ClusterIP   10.100.0.1     <none>        443/TCP   77d

### Additional troubleshooting tips

If the error still persists, use the following troubleshooting tips to identify the issue.

When you run a kubectl command, a request is sent to the Amazon EKS cluster API server. Then, the Amazon EKS authenticator tries to authenticate this request. Therefore, check EKS authenticator logs in CloudWatch to identify the issue.

1\. [Be sure that you turned on logging for your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html>).

2\. Open CloudWatch Log Insights.

3\. Select the log group for your cluster. Example: "/aws/eks/example-cluster/cluster".

4\. Run the following query:
    
    
    fields @timestamp, @message
    | filter @logStream like /authenticator/
    | sort @timestamp desc
    | limit 1000

Identify log lines for the same time interval when you got the error by running kubectl commands. You can find more information about the cause of the error in Amazon EKS authenticator logs.

  * If the issue is caused by using the incorrect IAM entity for kubectl, then review the kubectl kubeconfig and AWS CLI configuration. Make sure that you're using the correct IAM entity. For example, suppose that the logs look similar to the following. This output means that the IAM entity used by kubectl can't be validated. Be sure that the IAM entity used by kubectl exists in IAM and the entity's programmatic access is turned on.


    
    
    time="2022-12-26T20:46:48Z" level=warning msg="access denied" client="127.0.0.1:43440" error="sts getCallerIdentity failed: error from AWS (expected 200, got 403). Body: {\"Error\":{\"Code\":\"InvalidClientTokenId\",\"Message\":\"The security token included in the request is invalid.\",\"Type\":\"Sender\"},\"RequestId\":\"a9068247-f1ab-47ef-b1b1-cda46a27be0e\"}" method=POST path=/authenticate

  * If the issue because your IAM entity isn't mapped in aws-auth ConfigMap, or is incorrectly mapped, then review the aws-auth ConfigMap. Make sure that the IAM entity is mapped correctly and meets the requirements that are listed in the **You're not cluster creator** section. In this case, the EKS authenticator logs look similar to the following:


    
    
    time="2022-12-28T15:37:19Z" level=warning msg="access denied" arn="arn:aws:iam::XXXXXXXXXX:role/admin-test-role" client="127.0.0.1:33384" error="ARN is not mapped" method=POST path=/authenticate

  * If the aws-auth ConfigMap was updated and you lost access to the cluster, you can access the cluster using the IAM entity of the cluster creator. This is because the cluster creator doesn’t need to be mapped in the aws-auth ConfigMap.
  * If the cluster creator IAM entity was deleted, first create the same IAM user or role again. Then, access the cluster using this IAM entity by following the steps in **You're the cluster creator** section.
  * If the cluster creator is an IAM role that was created for an SSO user that was removed, then you can't create this IAM role again. In this case, reach out to AWS Support for assistance.



## Related information

[Turning on IAM user and role access to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>)

[How do I provide access to other IAM users and roles after cluster creation in Amazon EKS?](<https://aws.amazon.com/premiumsupport/knowledge-center/amazon-eks-cluster-access/>)

[Amazon EKS troubleshooting](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html>)

[Using RBAC authorization](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>) on the Kubernetes website

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
