Original URL: <https://repost.aws/knowledge-center/eks-persistent-volume-object>

# How do I troubleshoot issues when creating a Kubernetes persistent volume object dynamically using the Amazon EFS CSI controller?

I'm getting errors when I create an Amazon Elastic Kubernetes Service (Amazon EKS) pod that uses the persistent volume claim. The persistent volume is created dynamically and is in Pending state.

## Resolution

The [Amazon Elastic File System (Amazon EFS) CSI](<https://github.com/kubernetes-sigs/aws-efs-csi-driver>) driver uses the [AWS Identity and Access Management (IAM) role for service account](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>) (IRSA) feature. This feature requires that various components, including the OpenID Connect (OIDC) provider, IAM role, and access permissions are correctly configured. These components are configured using the IAM role policy and Kubernetes service account. Try the following troubleshooting steps based on the error that you get.

**Note:** If you receive errors when running AWS CLI commands, [make sure that you’re using the most recent version of the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

### storageclass.storage.k8s.io "<STORAGE_CLASS_NAME>" not found

This error indicates that the storage class referenced by the parameter **storageClassName** in your PersistentVolumeClaim object definition doesn't exist and must be created.

To resolve this error, do the following:

1\. Create a Kubernetes storage class object.

2\. Download a storage class manifest for Amazon EFS:
    
    
    curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/examples/kubernetes/dynamic_provisioning/specs/storageclass.yaml

3\. Edit the downloaded file. Find the following statement, and then replace the value for **fileSystemId** with your file system ID.
    
    
    fileSystemId: fs-582a03f344f0fc633 # Replace the filesystem id

4\. Deploy the storage class:
    
    
    kubectl apply -f storageclass.yaml

### failed to provision volume with StorageClass "<STORAGE_CLASS_NAME>": rpc error: code = InvalidArgument desc = File System does not exist: Resource was not found

This error indicates that the fileSystemId that's referenced by the storage class object either doesn't exist in the Region or is incorrect.

To troubleshoot this error, verify whether the Amazon EFS file system referenced in the storage class is correct and exists in the Region:
    
    
    kubectl get storageclass `kubectl get pvc ${PVC_NAME} -o jsonpath='{.spec.storageClassName}'` -o jsonpath='{.parameters.fileSystemId}'

**Note:** Be sure to replace **PVC_NAME** with the name of your PersistentVolumeClaim.

If the EFS file system (fileSystemId) that's returned doesn't exist in the Region, then delete the Kubernetes storage class object. Then, create it again by including the correct file system ID for the **fileSystemId** field.

### failed to provision volume with StorageClass "<STORAGE_CLASS_NAME>": rpc error: code = Internal desc = Failed to fetch File System info: Describe File System failed: WebIdentityErr: failed to retrieve credentials caused by: InvalidIdentityToken: No OpenIDConnect provider found in your account for https://oidc.eks.<REGION-CODE>.amazonaws.com/id/<OIDC ID> status code: 400, request id: <REQUEST ID>

This error indicates that the IAM OIDC identity provided isn't created in IAM for the Amazon EKS cluster.

1\. Retrieve your cluster's OIDC provider ID and store it in a variable:
    
    
    oidc_id=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5); echo $oidc_id

**Note:** Be sure to replace **CLUSTER_NAME** with the name of your cluster.

2\. Create an IAM OIDC identity provider for your cluster:
    
    
    eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} –-approve

**Note** : If you can't use the **eksctl** utility to create the IAM OIDC provider, [use the AWS Management Console](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>).

### failed to provision volume with StorageClass "<STORAGE_CLASS_NAME>": rpc error: code = Unauthenticated desc = Access Denied. Please ensure you have the right AWS permissions: Access denied

This error indicates that the IRSA doesn't have the required access permissions (Example: elasticfilesystem:CreateAccessPoint).

1\. Retrieve the service account that's used by the EFS CSI controller deployment:
    
    
    kubectl get deploy -n kube-system efs-csi-controller -o=jsonpath={'.spec.template.spec.serviceAccount'}

2\. Find the IAM role that's used by the service account:
    
    
    kubectl get sa -n kube-system ${SERVICE_ACCOUNT} -oyaml -o=jsonpath={'.metadata.annotations.eks\.amazonaws\.com/role-arn'}

3\. Download the IAM policy document from GitHub:
    
    
    curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json

4\. Create the IAM policy if it doesn't exist:
    
    
    aws iam create-policy --policy-name AmazonEKS_EFS_CSI_Driver_Policy --policy-document file://iam-policy-example.json

5\. Attach this IAM policy to the IAM role that you previously retrieved, annotated with the service account that's used by the EFS CSI controller deployment.
    
    
    aws iam attach-role-policy --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AmazonEKS_EFS_CSI_Driver_Policy --role-name ${IAM_ROLE_NAME}

**Note:**

You can retrieve the account ID by running the following command:
    
    
    aws sts get-caller-identity --query "Account" --output text

You can retrieve the IAM role by running the following command:
    
    
    echo $IAM_ROLE_ARN | cut -d "/" -f2

### Failed to fetch File System info: Describe File System failed: WebIdentityErr: failed to retrieve credentials caused by: AccessDenied: Not authorized to perform sts:AssumeRoleWithWebIdentity

You get this error because of one of the following reasons:

  * The IAM permission **sts:AssumeRoleWithWebIdentity** isn't provided.
  * The IAM OIDC identity provider listed in the trust relationship document that's attached to the IAM role isn't correct.
  * The Kubernetes service account (example: system:serviceaccount:kube-system:efs-csi-controller-sa) mentioned doesn't match the one that's used by the EFS CSI controller deployment.



To troubleshoot this error, do the following:

1\. Retrieve your cluster's OIDC provider ID and store it in a variable.
    
    
    oidc_id=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5); echo ${oidc_id}

Be sure to replace **CLUSTER_NAME** with the name of your cluster.

2\. Verify that the IAM OIDC provider ID exists in the AWS account:
    
    
    aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

3\. Review the trust relationship document that's attached to the IAM role:
    
    
    aws iam get-role --role-name ${IAM_ROLE_NAME} --output json --query "Role.AssumeRolePolicyDocument"

Verify that the Action sts:AssumeRoleWithWebIdentity is allowed. Also, confirm that the IAM OIDC ID matches the OIDC ID returned by the preceding command.

**Note:**

You can retrieve the IAM role by running the following command:
    
    
    echo $IAM_ROLE_ARN | cut -d "/" -f2

* * *

## Related information

[IAM roles for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>)

[Amazon EFS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
