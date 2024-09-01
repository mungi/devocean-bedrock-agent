Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-irsa-errors>

# How do I troubleshoot IRSA errors in Amazon EKS?

When I use AWS Identity and Access Management (IAM) roles for service accounts (IRSA) with Amazon Elastic Kubernetes Service (Amazon EKS), I get errors.

## Resolution

### Check the format of the IAM ARN

If you incorrectly formatted your IAM ARN in the service account annotation, then you get the following error:

"An error occurred (ValidationError) when calling the AssumeRoleWithWebIdentity  
operation: Request ARN is invalid"

The following is an example of an ARN with an incorrect format:
    
    
    eks.amazonaws.com/role-arn: arn:aws:iam::::1234567890:role/example

Because the ARN has an extra colon (**:**), the incorrect format of the ARN causes the error message. To verify the correct ARN format, see [IAM ARNs](<https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html#identifiers-arns>).

### Check if you have an IAM OIDC provider for your AWS account

If you didn't create an OpenID Connect (OIDC) provider, then you get the following error:

"An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: No OpenIDConnect provider found in your account for https://oidc.eks.region.amazonaws.com/id/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

To troubleshoot this error, get the IAM OIDC provider URL:
    
    
    aws eks describe-cluster --name cluster name --query "cluster.identity.oidc.issuer" --output text

**Note:** Replace **cluster name** with your cluster name.

The output looks similar to the following example:
    
    
    https://oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E

To list the IAM OIDC providers, run the following command:
    
    
    aws iam list-open-id-connect-providers | grep EXAMPLED539D4633E53DE1B716D3041E

**Note:** Replace **EXAMPLED539D4633E53DE1B716D3041E** with the IAM OIDC provider URL.

If the OIDC provider doesn't exist, then run the following **eksctl** command to create an OIDC provider:
    
    
    eksctl utils associate-iam-oidc-provider --cluster cluster name --approve

**Note:** Replace **cluster name** with your cluster name.

You can also use the AWS Management Console to [create an IAM OIDC provider for your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>).

### Verify the audience of the IAM OIDC provider

When you create an IAM OIDC provider, you must use **sts.amazonaws.com** as your audience. If the audience is incorrect, then you get the following error:

"An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: Incorrect token audience"

To check the audience of the IAM OIDC provider, run the following command:
    
    
    aws iam get-open-id-connect-provider --open-id-connect-provider-arn ARN-of-OIDC-provider

**Note:** Replace **ARN-of-OIDC-provider** with the ARN of your OIDC provider.

Under the **ClientIDList** parameter, the output must display **sts.amazonaws.com**. To use the Amazon EKS console to check the audience, complete the following steps:

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/home#/clusters>).
  2. Select the **name of your cluster** , and then choose the **Overview** tab.
  3. In the **Details** section, note the value of the OIDC provider URL.
  4. Open the [IAM console](<https://console.aws.amazon.com/iam/>).
  5. In the navigation pane, under **Access Management** , choose **Identity Providers**.
  6. Select the **provider** that matches the URL for your cluster.



To change the audience, complete the following steps:

  1. Open the [IAM console](<https://console.aws.amazon.com/iam/>).
  2. In the navigation pane, under **Access Management** , choose **Identity Providers**.
  3. Select the **provider** that matches the URL for your cluster.
  4. Choose **Actions** , and then choose **Add audience**.
  5. Add **sts.amazonaws.com**.



### Verify that you created the IAM OIDC resource with a root certificate thumbprint

If you didn't use a root certificate thumbprint to create the OIDC provider, then you get the following error:

"An error occurred (InvalidIdentityToken) when calling the AssumeRoleWithWebIdentity operation: OpenIDConnect provider's HTTPS certificate doesn't match configured thumbprint"

**Note:** Non-root certificate thumbprints are renewed annually. Root certificate thumbprints are renewed every decade. It's a best practice to use a root certificate thumbprint when you create an IAM OIDC.

For example, you use one of the following services to create your IAM OIDC:

  * AWS Command Line Interface (AWS CLI)
  * AWS Tools for PowerShell
  * IAM API



In this case, you must manually [obtain the thumbprint](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc_verify-thumbprint.html>). If you created your IAM OIDC in the IAM console, then it's a best practice to manually obtain the thumbprint. Use this thumbprint to verify that the console obtained the correct IAM OIDC.

To find the root certificate thumbprint and expiration date, run the following command:
    
    
    echo | openssl s_client -servername oidc.eks.your-region-code.amazonaws.com -showcerts -connect oidc.eks.your-region-code.amazonaws.com:443 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/{cert=""} {cert=cert $0 "\n"} /-----END CERTIFICATE-----/{last_cert=cert} END{printf "%s", last_cert}' | openssl x509 -fingerprint -noout -dates | sed 's/://g' | awk -F= '{print tolower($2)}'

**Note:** Replace **your-region-code** with the AWS Region that your cluster is located in.

Example output:
    
    
    9e99a48a9960b14926bb7f3b02e22da2b0ab7280 sep 2 000000 2009 gmt jun 28 173916 2034 gmt

In the preceding output, **9e99a48a9960b14926bb7f3b02e22da2b0ab7280** is the thumbprint. **sep 2 000000 2009 gmt** is the certificate start date and **jun 28 173916 2034** is the certificate expiration date.

### Check the configuration of your IAM role's trust policy

If you misconfigured the trust policy of the IAM role, then you get the following error:

"An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity"

To resolve this issue, make sure that you use the correct IAM OIDC provider. If the IAM OIDC provider is correct, then review the [IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>) to see if the trust policy's conditions are correctly configured.

### Verify that your pod identity webhook configuration exists and is valid

The pod identity webhook injects the necessary environment variables and projected volume. If you accidentally deleted or changed your webhook configuration, then IRSA stops working.

To verify that your webhook configuration exists and is valid, run the following command:
    
    
    kubectl get mutatingwebhookconfiguration pod-identity-webhook  -o yaml

If the **pod-identity-webhook** configuration doesn't exist, then run the following command to create it:
    
    
    CLUSTER_CA=$(aws eks describe-cluster --name CLUSTER_NAME --region REGION_CODE --query 'cluster.certificateAuthority.data' --output text);
    cat << EOF | kubectl apply -f -
    apiVersion: admissionregistration.k8s.io/v1
    kind: MutatingWebhookConfiguration
    metadata:
      name: pod-identity-webhook
    webhooks:
    - name: iam-for-pods.amazonaws.com
      clientConfig:
        url: "https://127.0.0.1:23443/mutate"
        caBundle: $CLUSTER_CA
      failurePolicy: Ignore
      rules:
      - operations: [ "CREATE" ]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
        scope: "*"
      reinvocationPolicy: IfNeeded
      sideEffects: None
      admissionReviewVersions: ["v1beta1"]
    EOF

**Note:** Replace **CLUSTER_NAME** with your cluster name and **REGION_CODE** with cluster Region.

### Verify that your pod identity webhook injects environment variables to your pods that use IRSA

To verify that your pod identity webook injects environment variables to your pods that use IRSA, run one of the following commands:
    
    
    kubectl get pod <pod-name> -n <ns> -o yaml | grep aws-iam-token

-or-
    
    
    kubectl get pod <pod-name> -n <ns> -o yaml | grep AWS_WEB_IDENTITY_TOKEN_FILE

### Verify that you use supported AWS SDKs

Review your AWS SDKs. Make sure that you [use an AWS SDK version](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html>) that allows you to assume an IAM role through the OIDC web identity token file.

## Related information

[Why can't I use an IAM role for the service account in my Amazon EKS pod?](<https://repost.aws/knowledge-center/eks-pods-iam-role-service-accounts>)

[How do I troubleshoot an OIDC provider and IRSA in Amazon EKS?](<https://repost.aws/knowledge-center/eks-troubleshoot-oidc-and-irsa>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
