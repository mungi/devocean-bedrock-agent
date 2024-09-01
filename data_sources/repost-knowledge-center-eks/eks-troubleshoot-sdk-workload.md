Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-sdk-workload>

# How do I troubleshoot common issues with AWS SDK workloads in Amazon EKS?

I used AWS SDK to develop a container application for Amazon Elastic Kubernetes Service (Amazon EKS). When I try to make calls to AWS services, I get an error.

## Resolution

When you deploy a container application that uses AWS SDK to an Amazon EKS cluster, you might receive one of the following errors:

  * **NoCredentialsError: Unable to locate credentials**
  * **EndpointConnectionError**
  * **ClientError: An error occurred (AccessDenied)**
  * **ClientError: An error occurred (UnauthorizedOperation)**



The specific error message depends on the AWS SDK programming language that your application uses. Refer to the following troubleshooting steps for your error.

### Unable to locate credentials

If Amazon EKS can't find your pod's credentials, then you see an error that's similar to the following message:

"File "/usr/local/lib/python2.7/site-packages/botocore/auth.py", line 315, in add_auth  
raise NoCredentialsError  
botocore.exceptions.NoCredentialsError: Unable to locate credentials"

This error occurs when you don't configure your pod's credentials, you don't configure the credentials properly, or your AWS SDK version isn't supported.

To resolve this error, use AWS Identity and Access Management (IAM) roles. Typically, you create and distribute AWS credentials for the SDK client in the application or with the Amazon EC2 instance's role. Instead, configure your pods to use [IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>). Associate an IAM role with a Kubernetes service account, and then configure your pods to use the service account.

**Important:** Your pods' containers must use an [AWS SDK version](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-minimum-sdk.html>) that supports assuming an IAM role through an OpenID Connect web identity token file.

### Could not connect to the endpoint URL

If your pod can't communicate with the AWS service endpoints, then you see an error that's similar to the following message:

"File "/usr/local/lib/python2.7/site-packages/botocore/retryhandler.py", line 359, _in_ _check_caught_exception  
raise caught_exception  
botocore.exceptions.EndpointConnectionError: Could not connect to the endpoint URL: "https://ec2.eu-west-1.amazonaws.com/"  
botocore.exceptions.EndpointConnectionError: Could not connect to the endpoint URL: "https://sts.eu-west-1.amazonaws.com/""

To resolve this error, troubleshoot DNS issues and confirm the following points:

**Check if CoreDNS pods are running in the cluster**

Run the following command:
    
    
    kubectl get pods --namespace=kube-system -l k8s-app=kube-dns -o wide

You see an output that's similar to the following example:
    
    
    NAME                       READY   STATUS    RESTARTS   AGE   IP                NODE                                            NOMINATED NODE   READINESS GATES  
    coredns-7f85bf9964-kz8lp   1/1     Running   0          15d   192.168.100.36    ip-192-168-101-156.eu-west-1.compute.internal   <none>           <none>  
    coredns-7f85bf9964-wjxvb   1/1     Running   0          15d   192.168.135.215   ip-192-168-143-137.eu-west-1.compute.internal   <none>           <none>

Be sure to have running worker nodes with sufficient capacity in the Amazon EKS cluster to successfully run the CoreDNS pods.

**Test endpoint resolution**

Verify that your CoreDNS pod and application pod can resolve the AWS service endpoint that you want your pod to call. Run the following command:
    
    
    nslookup SERVICE_ENDPOINT  
      
    nslookup ec2.eu-west-1.amazonaws.com  
      
    nslookup ec2.amazonaws.com

**Note:** Replace **SERVICE_ENDPOINT** with the ENDPOINT that's printed in the error message.

### An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation

If your pod can't request a temporary security credential, then you see an error that's similar to the following message:

"File "/usr/local/lib/python3.11/site-packages/botocore/client.py", line 960, _in_ _make_api_call  
raise error_class(parsed_response, operation_name)  
botocore.exceptions.ClientError: An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity"

To resolve this error, complete the following steps:

**Confirm the assumed IAM role**

Confirm that the Pod assumes an IAM role that's associated with a Kubernetes service account that exists in the cluster. Otherwise, the pod assumes the Amazon EKS node IAM role. To get the service account's IAM role ARN, run the following command:
    
    
    kubectl get serviceaccount -A  
      
    kubectl describe serviceaccount serviceaccount_name -n namespace_name | grep -i arn

**Note:** Replace **serviceaccount_name** and **namespace_name** with your own values.

You see an output that's similar to the following example:
    
    
    Annotations: eks.amazonaws.com/role-arn: arn:aws:iam::11112222333:role/AccessEC2role

**Check CloudTrail events**

Verify which IAM identity is denied access to perform the **AssumeRoleWithWebIdentity** **actionView**. To do this, check AWS CloudTrail events in the CloudTrail console.

  1. Log in to the [CloudTrail console](<https://console.aws.amazon.com/cloudtrail/home/>).
  2. In the navigation pane, choose **Event history**.
  3. In the **Lookup attributes** dropdown menu, change the selection from **Read-only** to **Event name**.
  4. In the **Enter an event name** search bar, enter **AssumeRoleWithWebIdentity** . Inspect the list of events that appears in the content pane. See the following example of a denied event:


    
    
    {  
        "eventVersion": "1.08",  
        "userIdentity": {  
            "type": "WebIdentityUser",  
            "userName": "system:serviceaccount:serverless:aws-sdk"  
        },  
        "eventName": "AssumeRoleWithWebIdentity",  
        "errorCode": "AccessDenied",  
        "errorMessage": "An unknown error occurred",  
        "requestParameters": {  
            "roleArn": "arn:aws:iam::11112222333:role/AccessEC2role",  
            "roleSessionName": "botocore-session-1675698641"  
        }  
    }

In this output, the **roleArn** must be the same IAM role that you configured for the pod's service account.  
The **userName** (**system:serviceaccount:serverless:aws-sdk**) must match the service account name and its namespace. The format for this name is **system:serviceaccount:namespace:serviceaccount_name**.

**Configure the pod’s service account IAM role**

In the [IAM Console](<https://console.aws.amazon.com/iam/home>), configure the pod's service account IAM role with the correct IAM trust policy statement:
    
    
         {  
                "Effect": "Allow",  
                "Principal": {  
                    "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.region_code.amazonaws.com/id/EXAMPLE11111122222333334444ABCD"  
                },  
                "Action": "sts:AssumeRoleWithWebIdentity",  
                "Condition": {  
                    "StringEquals": {  
                        "oidc.eks.region_code.amazonaws.com/id/EXAMPLE11111122222333334444ABCD:sub": "system:serviceaccount:namespace_name:serviceaccount_name",  
                        "oidc.eks.region_code.amazonaws.com/id/EXAMPLE11111122222333334444ABCD:aud": "sts.amazonaws.com"  
                    }  
                }  
        }     

**Note:** Replace **region_code** , **ACCOUNT_ID** , **EXAMPLE11111122222333334444ABCD** , **serviceaccount_name** and **namespace_name** with your own values.

### An error occurred (UnauthorizedOperation)

The IAM role that you configured for the pod's service account might not be authorized to call other AWS services. In this case, you see an error that's similar to the following message:

File "/usr/local/lib/python3.11/site-packages/botocore/client.py", line 960, _in_ _make_api_call  
raise error_class(parsed_response, operation_name)  
botocore.exceptions.ClientError: An error occurred (UnauthorizedOperation) when calling the DescribeInstances operation: You are not authorized to perform this operation.

To resolve this error, complete the following steps:

  1. Confirm that the pod assumes an IAM role that's associated with a Kubernetes service account. To do this, see the previous section **Confirm the assumed IAM role**. Note the role ARN that this step returns.
  2. Open the [IAM console](<https://console.aws.amazon.com/iam/>). In the navigation pane, choose **Roles**. Then, search and select the role ARN from Step 1.
  3. Under the **Permissions** tab, attach the necessary [IAM policy permissions](<https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html>) to the IAM role.



For an example pod, see [Sample pod running AWS Python SDK with web federated identity provider as credential provider](<https://github.com/aws-samples/aws-eks-se-samples/tree/main/examples/kubernetes/how-to-python-sdk-containers>) on GitHub.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
