Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-oidc-and-irsa>

# How do I troubleshoot an OIDC provider and IRSA in Amazon EKS?

My pods can't use the AWS Identity and Access Management (IAM) role permissions with the Amazon Elastic Kubernetes Service (Amazon EKS) account token.

## Resolution

### Check if you have an existing IAM OIDC provider for your cluster

If a provider already exists, then you receive an error similar to the following: "WebIdentityErr: failed to retrieve credentials\ncaused by: InvalidIdentityToken: No OpenIDConnect provider found in your account for https://oidc.eks.eu-west-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E\n\tstatus code: 400";

To check if you have an existing IAM OIDC provider, complete the following steps:

  1. Check your cluster's OIDC provider URL:
    
        $ aws eks describe-cluster --name cluster_name --query "cluster.identity.oidc.issuer" --output text

Example output:
    
        https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E

  2. List the IAM OIDC providers in your account. Replace **EXAMPLED539D4633E53DE1B716D3041E** with the value that you received from the previous command:
    
        aws iam list-open-id-connect-providers | grep EXAMPLED539D4633E53DE1B716D3041E

Example output:
    
        "Arn": "arn:aws:iam::111122223333:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"




If the command returns an output, then you already have a provider for your cluster. If the command doesn't return an output, then you must [create an IAM OIDC provider](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>).

### Check if your IAM role has the required permissions and an attached IAM policy

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

To check that your IAM role has the required permissions, complete the following steps:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>).
  2. In the navigation pane, choose **Roles**.
  3. Select the **role** that you want to verify.
  4. Under the **Permissions** tab, verify that the required policy is attached to the role.
  5. Verify that the IAM role trust relations are correctly set.



To check that your IAM role has an attached policy, complete the following steps:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>).

  2. In the navigation pane, choose **Roles**.

  3. Select the **role** that you want to check.

  4. Choose the **Trust Relationships** tab. Verify that the format of your policy matches the format of the following JSON policy:
    
        {  "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub": "system:serviceaccount:SERVICE_ACCOUNT_NAMESPACE:SERVICE_ACCOUNT_NAME",
              "oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:aud": "sts.amazonaws.com"
            }
          }
        }
      ]
    }

To verify trust relations, run the [get-role](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/get-role.html>) command in the AWS Command Line Interface (AWS CLI):
    
        $ aws iam get-role --role-name EKS-IRSA

**Note:** Replace **EKS-IRSA** with your IAM role name.  
In the output JSON, look for the **AssumeRolePolicyDocument** section.  
Example output:
    
        {  "Role": {
        "Path": "/",
        "RoleName": "EKS-IRSA",
        "RoleId": "AROAQ55NEXAMPLELOEISVX",
        "Arn": "arn:aws:iam::ACCOUNT_ID:role/EKS-IRSA",
        "CreateDate": "2021-04-22T06:39:21+00:00",
        "AssumeRolePolicyDocument": {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E"
              },
              "Action": "sts:AssumeRoleWithWebIdentity",
              "Condition": {
                "StringEquals": {
                  "oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:aud": "sts.amazonaws.com",
                  "oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E:sub": "system:serviceaccount:SERVICE_ACCOUNT_NAMESPACE:SERVICE_ACCOUNT_NAME"
                }
              }
            }
          ]
        },
        "MaxSessionDuration": 3600,
        "RoleLastUsed": {
          "LastUsedDate": "2021-04-22T07:01:15+00:00",
          "Region": "AWS_REGION"
        }
      }
    }

**Note:** Depending on your use case, update the AWS Region, Kubernetes service account name, and Kubernetes namespace.




### Check if you created a service account

Run the following command:
    
    
    $ kubectl get sa -n YOUR_NAMESPACE

**Note:** Replace **YOUR_NAMESPACE** with your Kubernetes namespace.

Example output: 
    
    
    NAME      SECRETS   AGEdefault   1         28d
    irsa      1         66m

If you don't have a service account, then see [Configure service accounts for pods](<https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/>) on the Kubernetes website.

### Verify that the service account has the correct IAM role annotations

To verify that your service account has the correct IAM role annotations, run the following command:
    
    
    $ kubectl describe sa irsa -n YOUR_NAMESPACE

**Note:** Replace **irsa** with your Kubernetes service account name and **YOUR_NAMESPACE** with your Kubernetes namespace.

Example output:
    
    
    Name:                irsaNamespace:           default
    Labels:              none
    Annotations:         eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/IAM_ROLE_NAME
    Image pull secrets:  none
    Mountable secrets:   irsa-token-v5rtc
    Tokens:              irsa-token-v5rtc
    Events:              none

### Verify that you correctly specified the serviceAccountName in your pod

To verify the **serviceAccountName** , run the following command:
    
    
    $ kubectl get pod POD_NAME  -o yaml -n YOUR_NAMESPACE| grep -i serviceAccountName:

**Note:** Replace **POD_NAME** and **YOUR_NAMESPACE** with your Kubernetes pod and namespace.

Example output: 
    
    
    serviceAccountName: irsa

### Check the environment variables and permissions

Look for **AWS_ROLE_ARN** and **AWS_WEB_IDENTITY_TOKEN_FILE** in the pod's environment variables:
    
    
    $ kubectl -n YOUR_NAMESPACE exec -it POD_NAME -- env | grep AWS

Example output: 
    
    
    AWS_REGION=ap-southeast-2AWS_ROLE_ARN=arn:aws:iam::111122223333:role/EKS-IRSA
    AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
    AWS_DEFAULT_REGION=ap-southeast-2

### Verify that the application uses a supported AWS SDK

The SDK version must be greater than or equal to the following values:
    
    
    Java (Version 2) — 2.10.11Java — 1.11.704
    Go — 1.23.13
    Python (Boto3) — 1.9.220
    Python (botocore) — 1.12.200
    AWS CLI — 1.16.232
    Node — 3.15.0
    Ruby — 2.11.345
    C++ — 1.7.174
    .NET — 3.3.659.1
    PHP — 3.110.7

To check for latest supported SDK version, see [Using a supported AWS SDK](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html>).

### Recreate pods

If you created pods before you applied IRSA, then run the following command to recreate the pods: 
    
    
    $ kubectl rollout restart deploy nginx

Example output:
    
    
    deployment.apps/nginx restarted

For daemonsets or statefulsets deployments, run the following command:
    
    
    $ kubectl rollout restart deploy DEPLOYMENT_NAME

If you created only one pod, then you must delete the pod and recreate it:

  1. Run the following command to delete the pod:
    
        $ kubectl delete pod POD_NAME

**Note:** Replace **POD_NAME** with the name of your pod.
  2. Run the following command to recreate the pod:
    
        $ kubectl apply -f SPEC_FILE

**Note:** Replace **SPEC_FILE** with your Kubernetes manifest file path and file name.



### Verify that the audience is correct

If you created the OIDC provider with the incorrect audience, then you receive the following error: "Error - An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Incorrect token audience".

Check the IAM identity provider for your cluster. Your **ClientIDList** is **sts.amazonaws.com** :
    
    
    $ aws iam get-open-id-connect-provider --open-id-connect-provider-arn arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E

Example output:
    
    
    {  "Url": "oidc.eks.AWS_REGION.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E",
      "ClientIDList": [
        "sts.amazonaws.com"
      ],
      "ThumbprintList": [
        "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
      ],
      "CreateDate": "2021-01-21T04:29:09.788000+00:00",
      "Tags": []
    }

### Verify that you configured the correct thumbprint

If the thumbprint that's configured in the IAM OIDC isn't correct, then you receive the following error: "failed to retrieve credentials caused by: InvalidIdentityToken: OpenIDConnect provider's HTTPS certificate doesn't match configured thumbprint".

To automatically configure the correct thumbprint, use **eksctl** or the AWS Management Console to create the IAM identity provider. For other ways to obtain a thumbprint, see [Obtaining the thumbprint for an OpenID Connect identity provider](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html>).

### For the AWS China Region, check the AWS_DEFAULT_REGION environment variable

For an IRSA-applied pod or daemonset that's deployed to a cluster in the AWS China Region, set the **AWS_DEFAULT_REGION** environment variable in the pod specification. If you don't set this variable, then the pod or daemonset might receive the following error: "An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid".

To add the **AWS_DEFAULT_REGION** environment variable to your pod or daemonset specification, run a command similar to the following example:
    
    
    apiVersion: apps/v1kind: Deployment
    metadata:
      name: my-app
    spec:
      template:
        metadata:
          labels:
            app: my-app
        spec:
          serviceAccountName: my-app
          containers:
          - name: my-app
            image: my-app:latest
            env:
            - name: AWS_DEFAULT_REGION
              value: "AWS_REGION"
    ...

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
