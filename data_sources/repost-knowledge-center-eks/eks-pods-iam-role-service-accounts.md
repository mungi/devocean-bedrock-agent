Original URL: <https://repost.aws/knowledge-center/eks-pods-iam-role-service-accounts>

# Why can't I use an IAM role for the service account in my Amazon EKS pod?

I try to use an AWS Identity and Access Management (IAM) role for a service account. My Amazon Elastic Kubernetes Service (Amazon EKS) pod fails to assume the assigned IAM role with an authorization error. Or, my pod tries to use the default IAM role assigned to the Amazon EKS node instead of the IAM role assigned to my pod.

## Resolution

**Note** : If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

### Verify that you have an IAM OIDC identity provider for your Amazon EKS cluster

[Create an IAM OIDC provider for your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>), if you don't already have one. You must have an OIDC identity provider for your cluster to use an IAM role for your service account.

Then, verify that the OIDC identity provider is configured correctly:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>). From the navigation pane, choose **Identity providers.**
  2. In the **Provider** column, identify and note the OIDC provider URL.
  3. In a separate tab or window, open the [Amazon EKS console](<https://console.aws.amazon.com/eks/>). Then, choose **Clusters** from the navigation pane.
  4. Choose your cluster, and then choose the **Configuration** tab.
  5. In the **Details** section, note the value of the **OpenID Connect provider URL** property.
  6. Verify that the OIDC provider URL from the Amazon EKS console (step 5) matches the OIDC provider URL from the IAM console (step 2).  
If the OIDC provider URL for your Amazon EKS cluster doesn't match any of the OIDC provider URLs in the IAM console, then you must [create a new IAM OIDC provider](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>).



### Validate your IAM role policies and trust policy configuration

Your IAM role might not have the full range of permissions needed. Your IAM role's trust relationship policy could also have syntax errors, if you created your IAM role with the [AWS Management Console or AWS CLI](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).

To validate your IAM role policies and check for syntax errors in your trust policy, do the following:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>).
  2. In the navigation pane, choose **Roles** , and then choose your role.
  3. Choose the **Permissions** tab on your role's page, and then verify that all your required permissions are assigned to the role.
  4. Choose the **Trust Relationships** tab, and then choose **Edit trust relationship**.
  5. In the policy document for your trust relationship, verify that the format of your policy matches the format of the following JSON policy:
    
        {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::your-account-id:oidc-provider/oidc.eks.your-region-code.amazonaws.com/id/EXAMPLE_OIDC_IDENTIFIER"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.your-region-code.amazonaws.com/id/EXAMPLE_OIDC_IDENTIFIER:sub": "system:serviceaccount:your-namespace:your-service-account",
              "oidc.eks.your-region-code.amazonaws.com/id/EXAMPLE_OIDC_IDENTIFIER:aud": "sts.amazonaws.com"
            }
          }
        }
      ]
    }

In your JSON policy, review the format of the **Federated** property line and the **StringEquals** property line. In the **Federated** line, confirm that your AWS Region code (**your-region-code**), account ID (**your-account-id**), and unique OIDC identifier (**EXAMPLE_OIDC_IDENTIFIER**) are formatted correctly. In the **StringEquals** line, confirm that your Region code (**your-region-code**), OIDC unique identifier (**EXAMPLE_OIDC_IDENTIFIER**), Kubernetes namespace (**your-namespace**), and Kubernetes service account name (**your-namespace**) are formatted correctly.
  6. If you edit your policy document to correct formatting errors, then choose **Update Trust Policy**.



### Confirm that your service account exists and has a properly formatted annotation for the IAM role's ARN

  1. Confirm that your Kubernetes service account exists:
    
        $ kubectl get serviceaccount YOUR_ACCOUNT_NAME -n YOUR_NAMESPACE -o yaml

**Note:** Replace **YOUR_ACCOUNT_NAME** with your account name. Replace **YOUR_NAMESPACE** with your namespace.  
If the preceding command doesn't return a service account name, then create a service account. For more information, see [Use more than one ServiceAccount](<https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-multiple-service-accounts>) on the Kubernetes website.

  2. Confirm that your service account has the name that you expect. Also, confirm that its **role-arn** annotation is correctly formatted. For example:
    
        apiVersion: v1
    kind: ServiceAccount
    metadata:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::012345678912:role/my-example-iam-role
      name: my-example-serviceaccount
      namespace: my-test-namespace




### Use a test pod to verify that the service account works

Run a test pod to verify that the service account works correctly. Then, check if the pod can mount environment variables correctly and can assume the specified IAM role.

  1. Create a local YAML file called **awscli-pod.yaml**. For example:
    
        apiVersion: v1
    kind: Pod
    metadata:
      name: awscli
      labels:
        app: awscli
    spec:
      serviceAccountName: YOUR_SERVICE_ACCOUNT
      containers:
      - image: amazon/aws-cli
        command:
          - "sleep"
          - "604800"
        imagePullPolicy: IfNotPresent
        name: awscli
      restartPolicy: Always

**Note:** Replace **YOUR_SERVICE_ACCOUNT** with your Kubernetes service account name.

  2. Create the test pod (from the YAML file) in your namespace:
    
        $ kubectl apply -f ./awscli-pod.yaml -n YOUR_NAMESPACE

**Note:** Replace **YOUR_NAMESPACE** with your namespace.

  3. Confirm that the **awscli** pod has the correct [environment variables](<https://docs.aws.amazon.com/eks/latest/userguide/pod-configuration.html>):
    
        $ kubectl exec -n YOUR_NAMESPACE awscli -- env | grep AWS

The output looks similar to the following:
    
        AWS_ROLE_ARN=arn:aws:iam::ACCOUNT_ID:role/IAM_ROLE_NAME
    AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

  4. Confirm that the test pod is with the correct IAM role:
    
        $ kubectl exec -it awscli -n YOUR_NAMESPACE -- aws sts get-caller-identity

The output looks similar to the following:
    
        {
        "UserId": "REDACTEDY471234567890:botocore-session-1632772568",
        "Account": "012345678912",
        "Arn": "arn:aws:sts::012345678912:assumed-role/your-iam-role/botocore-session-1632772568"
    }

Note the **Arn** value, including the IAM role name that you receive in this output.

  5. After you verify the IAM role, delete the **awscli** pod:
    
        $ kubectl delete -f ./awscli-pod.yaml -n YOUR_NAMESPACE

If the **awscli** pod shows the correct IAM role, then the IAM roles for service accounts feature work correctly.




The preceding steps confirm that the IAM token is correctly mounted to the pod. If your application still can't use the token file correctly, then there might be an issue at the application or SDK level. This issue can be related to how the application ingests AWS credentials or because the SDK version isn't supported. For more information, see [Using the Default Credential Provider Chain](<https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html#credentials-default>), [Credentials](<https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html>) on the Boto3 website, and [Using a supported AWS SDK](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
