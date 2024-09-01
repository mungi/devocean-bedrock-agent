Original URL: <https://repost.aws/knowledge-center/eks-configure-sso-user>

# How do I configure an SSO user to access my Amazon EKS cluster?

I'm using AWS IAM Identity Center (successor to AWS Single Sign-On). However, I'm unable to access the Amazon Elastic Kubernetes Service (Amazon EKS) cluster. I want to configure the SSO user to access my cluster.

## Resolution

Be sure that the following prerequisites are met:

  * [You turned on and configured IAM Identity Center](<https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html>).
  * Your SSO user is associated with the AWS account where the Amazon EKS cluster exists.



**Note:** The following steps use kubectl to access the cluster. After you configure kubectl access, you can see the cluster resources in the Amazon EKS console by logging in as the IAM Identity Center user.

**Note:** If you receive errors when running the AWS Command Line Interface (AWS CLI) commands, [confirm that you're running a recent version of the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html#general-latest>).

### Configure AWS CLI to use your SSO user

Create an AWS Command Line Interface (AWS CLI) profile that uses the SSO authentication when running the AWS CLI commands. For more information, see [Configuring the AWS CLI to use AWS IAM Identity Center (successor to AWS Single Sign-On)](<https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html>).

The following is an example of AWS CLI SSO configuration using the automatic procedure:
    
    
    aws configure sso
    SSO start URL [None]: https://my-sso-portal.awsapps.com/start
    SSO region [None]: us-east-1

The AWS CLI attempts to open your default browser and begin the login process for your IAM Identity Center account.
    
    
    Attempting to automatically open the SSO authorization page in your default browser.

If the AWS CLI can't open the browser, you get the following message with instructions on how to manually start the login process:
    
    
    If the browser does not open or you wish to use a different device to authorize this request, open the following URL:
    https://device.sso.us-east-2.amazonaws.com/
    Then enter the code:
    XXXX-XXXX
    The only AWS account available to you is: 123456789999
    Using the account ID 123456789999
    The only role available to you is: ViewOnlyAccess
    Using the role name "ViewOnlyAccess"
    CLI default client Region [us-east-2]:
    CLI default output format [json]:
    CLI profile name [ViewOnlyAccess-123456789999]: test-profile
    To use this profile, specify the profile name using --profile, as shown:
    aws s3 ls --profile test-profile

You can now run the AWS CLI commands using this new profile. This configuration allows your SSO user to do the following:

  * Authenticate with AWS.
  * Assume an AWS Identity and Management (IAM) role that was created by the IAM Identity Center.



Example:
    
    
    $ aws sts get-caller-identity
    {
        "UserId": "AROAXMRV33N1234567890:test-user",
        "Account": "123456789999",
        "Arn": "arn:aws:sts::123456789999:assumed-role/AWSReservedSSO_ViewOnlyAccess_05a3861234567890/test-user"
    }

### Configure kubectl context to use AWS CLI profile that's created for SSO

Kubectl uses AWS CLI commands. Therefore, you must specify the new AWS CLI profile in kubectl's current context. To update kubectl context to use the new profile, run the following command:
    
    
    aws eks update-kubeconfig --name $CLUSTER-NAME --profile test-profile

After you run this command, kubectl uses the profile **test-profile** to authenticate with the cluster API server.

### Build an ARN version by excluding the path

The IAM roles that are mapped in aws-auth ConfigMap don't include path. By default, the Amazon Resource Name (ARN) of the IAM role that's associated with your SSO user includes path.

Example:
    
    
    arn:aws:iam::123456789999:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_ViewOnlyAccess_05a3861234567890

If you add the full ARN to the aws-auth ConfigMap, your SSO user isn't authenticated. You can't access your cluster using your SSO user. Be sure to build a version of this ARN without including the path. This version must be used in the next step

Example:
    
    
    arn:aws:iam::123456789000:role/AWSReservedSSO_ViewOnlyAccess_05a38657af2a0a01

You can also get the IAM role without the path by running the following commands:
    
    
    ssorole=$(aws sts get-caller-identity --query Arn --output text --profile test-profile | cut -d/ -f2)
    account=$(aws sts get-caller-identity --query Account --output text --profile  test-profile)
    echo "arn:aws:iam::$account:role/$ssorole"
    arn:aws:iam::123456789000:role/AWSReservedSSO_ViewOnlyAccess_05a38657af2a0a01

### Add the ARN to the aws-auth ConfigMap

For your SSO user to access the Amazon EKS cluster, the IAM role that's associated with your SSO user must be mapped to Kubernetes RBAC permissions. To do this, include the IAM role ARN without the path in the aws-auth ConfigMap. Then, map it to the Kubernetes user and the groups that are linked to the Kubernetes Role and RoleBinding (or ClusterRole and ClusterRoleBinding). Use instructions from either of the following sections based on your use case.

**SSO user with cluster-wide admin permissions**

By default, the Kubernetes group **system:masters** provides cluster-wide admin permissions. This group is linked to the ClusterRole cluster-admin and the ClusterRoleBinding cluster-admin. Therefore, you don't need to create new ClusterRole and ClusterBindingRole objects. You need to only map the IAM role without path to the **system:masters** group.

To do this, edit the aws-auth ConfigMap:
    
    
    kubectl edit configmap aws-auth -n kube-system

Then, add the following:
    
    
    - groups:
      - system:masters
      rolearn: arn:aws:iam::123456789000:role/AWSReservedSSO_ViewOnlyAccess_05a38657af2a0a01
      username: cluster-admin

**SSO user with namespace-bound read permissions**

In this case, you must create a Role and a RoleBinding with read permissions within a specific namespace. Then, link these objects to the IAM role using a custom user name or group name in the aws-auth ConfigMap.

1\. Create a Kubernetes Role object that allows only read permissions in your desired namespace:
    
    
    cat << EOF | kubectl apply -f -
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      namespace: $MY-NAMESPACE
      name: reader-role
    rules:
    - apiGroups: [""] # "" indicates the core API group
      resources: ["*"]
      verbs: ["get", "watch", "list"]
    EOF

**Note:**

  * Replace **$MY-NAMESPACE** with the name of your namespace.
  * Replace **reader-role** with your custom user name.



2\. Create a Kubernetes RoleBinding object that links Kubernetes role permissions to the group **read-only-group** :
    
    
    cat <<EOF | kubectl apply -f -
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: reader-binding
      namespace: MY-NAMESPACE
    subjects:
    - kind: Group
      name: read-only-group
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: Role
      name: reader-role
      apiGroup: rbac.authorization.k8s.io
    EOF

3\. Map the IAM role ARN without path to the group **read-only-group** in aws-auth ConfigMap.

You can map the IAM role automatically by running the following command:
    
    
    eksctl create iamidentitymapping \
        --cluster $CLUSTER-NAME \
        --region $REGION \
        --arn arn:aws:iam::123456789000:role/AWSReservedSSO_ViewOnlyAccess_05a38657af2a0a01 \
        --group read-only-group \
        --no-duplicate-arns \
        --username read-only-user1

**Note** : Replace **$CLUSTER-NAME** and **$REGION** with the name of your cluster and Region, respectively. Or, you can map the IAM role manually. To do this, edit the aws-auth ConfigMap:
    
    
    kubectl edit configmap aws-auth -n kube-system

Then, add the following under the **mapRoles** section:
    
    
    - groups:
      - read-only-group
      rolearn: arn:aws:iam::123456789000:role/AWSReservedSSO_ViewOnlyAccess_05a38657af2a0a01
      username: read-only-user1

**Important:** The IAM role must appear only once in the aws-auth ConfigMap. Therefore, be sure that only one section includes the IAM role.

You can now use your SSO user to access your cluster:
    
    
    $ kubectl get pod
    NAME    READY   STATUS    RESTARTS   AGE
    web-0   1/1     Running   0          24h

* * *

## Related information

[Turning on IAM user and role access to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
