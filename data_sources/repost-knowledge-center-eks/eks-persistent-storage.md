Original URL: <https://repost.aws/knowledge-center/eks-persistent-storage>

# How do I use persistent storage in Amazon EKS?

I want to use persistent storage in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

To use persistent storage in Amazon EKS, complete the steps for one of the following options:

  * Deploy and test the [Amazon Elastic Block Store (Amazon EBS) Container Storage Interface (CSI) driver](<https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>).
  * Deploy and test the [Amazon Elastic File System (Amazon EFS) Container Storage Interface (CSI) driver](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>).



**Note:** It's a best practice to install the latest version of the drivers. For steps on how to install the latest drivers, see [aws-ebs-csi-driver](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver#deploy-driver>) and [aws-efs-csi-driver](<https://github.com/kubernetes-sigs/aws-efs-csi-driver>) on the GitHub website.

## Resolution

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

**Prerequisites:**

  * [Install the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html>).
  * Use **kubectl** version 1.14 or later for the commands. For more information, see [Installing or updating kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>).
  * Set AWS Identity and Access Management (IAM) permissions to **Create**. Then, attach a policy to the Amazon EKS worker node role **CSI Driver Role**.
  * Create your Amazon EKS cluster, and join your worker nodes to the cluster.  
**Note:** Run the **kubectl** get nodes command to verify that your worker nodes are attached to your cluster.
  * To verify that your AWS IAM OpenID Connect (OIDC) provider exists for your cluster, run the following command:
    
        aws eks describe-cluster --name your_cluster_name --query "cluster.identity.oidc.issuer" --output text

**Note:** Replace **your_cluster_name** with your cluster name.
  * To verify that your IAM OIDC provider is configured, run the following command:
    
        aws iam list-open-id-connect-providers | grep <ID of the oidc provider>

**Note:** Replace **ID of the oidc provider** with your OIDC ID. If you receive a "No OpenIDConnect provider found in your account" error, then create an IAM OIDC provider.
  * Install or update **eksctl**. For instructions, see [Installation](<https://eksctl.io/installation/>) on the eksctl website.
  * To create an IAM OIDC provider, run the following command:
    
        eksctl utils associate-iam-oidc-provider --cluster my-cluster --approve

**Note:** Replace **my-cluster** with your cluster name.



### Amazon EBS CSI driver

**Deploy the Amazon EBS CSI driver**

Complete the following steps:

  1. Create an IAM trust policy file that's similar to the following example:
    
        cat <<EOF > trust-policy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<your OIDC ID>"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>:aud": "sts.amazonaws.com",
              "oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            }
          }
        }
      ]
    }
    EOF

**Note:** Replace **YOUR_AWS_ACCOUNT_ID** with your AWS account ID, **YOUR_AWS_REGION** with your AWS Region, and **your OIDC ID** with your OIDC ID.

  2. Create an IAM role that's named **AmazonEKS_EBS_CSI_DriverRole** :
    
        aws iam create-role 
     --role-name AmazonEKS_EBS_CSI_DriverRole 
     --assume-role-policy-document file://"trust-policy.json"

  3. Attach the driver's AWS managed IAM policy to the IAM role:
    
        aws iam attach-role-policy 
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy 
    --role-name AmazonEKS_EBS_CSI_DriverRole

  4. Deploy the Amazon EBS CSI driver.  
**Note:** To deploy the EBS CSI driver, you can use Kustomize, Helm, or an [Amazon EKS managed add-on](<https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html>). For instructions on how to deploy the EBS CSI driver, see [Installation](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/install.md>) on the GitHub website.




**Test the Amazon EBS CSI driver**

[Test your Amazon EBS CSI driver with a sample application](<https://docs.aws.amazon.com/eks/latest/userguide/ebs-sample-app.html>) that uses dynamic provisioning for the pods. The Amazon EBS volume is provisioned on demand.

### Amazon EFS CSI driver

**Create an IAM role for the CSI driver**

Complete the following steps:

  1. Download the IAM policy document from GitHub:
    
        curl -o iam-policy-example.json https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json

  2. Create an IAM policy:
    
        aws iam create-policy 
        --policy-name AmazonEKS_EFS_CSI_Driver_Policy 
        --policy-document file://iam-policy-example.json

  3. To determine your cluster's OIDC provider ID, run the following command:
    
        aws eks describe-cluster --name your_cluster_name --query "cluster.identity.oidc.issuer" --output text

**Note:** Replace **your_cluster_name** with your cluster name.

  4. Create the following IAM trust policy, and then grant the **AssumeRoleWithWebIdentity** action to your Kubernetes service account:
    
        cat <<EOF > trust-policy.json
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
            }
          }
        }
      ]
    }
    EOF

**Note:** Replace **YOUR_AWS_ACCOUNT_ID** with your account ID, **YOUR_AWS_REGION** with your AWS Region, and **XXXXXXXXXX45D83924220DC4815XXXXX** with your cluster's OIDC provider ID.

  5. Create an IAM role:
    
        aws iam create-role 
      --role-name AmazonEKS_EFS_CSI_DriverRole 
      --assume-role-policy-document file://"trust-policy.json"

  6. Attach your new IAM policy to the role:
    
        aws iam attach-role-policy 
      --policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AmazonEKS_EFS_CSI_Driver_Policy 
      --role-name AmazonEKS_EFS_CSI_DriverRole

  7. Save the following contents to a file that's named **efs-service-account.yaml** :
    
        apiVersion: v1
    kind: ServiceAccount
    metadata:
      labels:
        app.kubernetes.io/name: aws-efs-csi-driver
      name: efs-csi-controller-sa
      namespace: kube-system
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::<AWS_ACCOUNT_ID>:role/AmazonEKS_EFS_CSI_DriverRole

  8. Create the Kubernetes service account on your cluster:
    
        kubectl apply -f efs-service-account.yaml

**Note:** The Kubernetes service account that's named **efs-csi-controller-sa** is annotated with the IAM role that you created.

  9. Download the manifest from the public Amazon ECR registry and use the images to install the driver:
    
        $ kubectl kustomize "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.5" > public-ecr-driver.yaml

**Note:** To install the EFS CSI driver, you can use Helm and a Kustomize with AWS Private or Public Registry. For instructions on how to install the EFS CSI Driver, see the [AWS EFS CSI driver](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/README.md>) on the GitHub website.

  10. Edit the file **public-ecr-driver.yaml** and annotate **efs-csi-controller-sa** Kubernetes service account section with the IAM role's ARN:
    
        apiVersion: v1
    kind: ServiceAccount
    metadata:
      labels:
        app.kubernetes.io/name: aws-efs-csi-driver
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::<accountid>:role/AmazonEKS\_EFS\_CSI\_DriverRole
      name: efs-csi-controller-sa
      namespace: kube-system




**Deploy the Amazon EFS CSI driver**

Complete the following steps:

  1. Apply the manifest:
    
        $ kubectl apply -f public-ecr-driver.yaml

  2. If your cluster contains only AWS Fargate pods (no nodes), then run the following command to deploy the driver (all Regions):
    
        kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/deploy/kubernetes/base/csidriver.yaml




**Create an Amazon EFS File system**

Complete the following steps:

  1. To get the virtual private cloud (VPC) ID of your Amazon EKS cluster, run the following command:
    
        aws eks describe-cluster --name your_cluster_name --query "cluster.resourcesVpcConfig.vpcId" --output text

**Note:** Replace **your_cluster_name** with your cluster name.
  2. To get the CIDR range for your VPC cluster, run the following command:
    
        aws ec2 describe-vpcs --vpc-ids YOUR_VPC_ID --query "Vpcs[].CidrBlock" --output text

**Note:** Replace the **YOUR_VPC_ID** with your VPC ID.
  3. Create a security group that allows inbound network file system (NFS) traffic for your Amazon EFS mount points:
    
        aws ec2 create-security-group --description efs-test-sg --group-name efs-sg --vpc-id YOUR_VPC_ID

**Note:** Replace **YOUR_VPC_ID** with your VPC ID. Note the **GroupId** to use later.
  4. To allow resources in your VPC to communicate with your Amazon EFS file system, add an NFS inbound rule:
    
        aws ec2 authorize-security-group-ingress --group-id sg-xxx --protocol tcp --port 2049 --cidr YOUR_VPC_CIDR

**Note:** Replace **YOUR_VPC_CIDR** with your VPC CIDR and **sg-xxx** with your security group ID.
  5. Create an Amazon EFS file system for your Amazon EKS cluster:
    
        aws efs create-file-system --creation-token eks-efs

**Note:** Note the **FileSystemId** to use later.
  6. To create a mount target for Amazon EFS, run the following command:
    
        aws efs create-mount-target --file-system-id FileSystemId --subnet-id SubnetID --security-group sg-xxx

**Important:** Run the preceding command for all the Availability Zones with the **SubnetID** in the Availability Zone where your worker nodes are running. Replace **FileSystemId** with your EFS file system's ID, **sg-xxx** with your security group's ID, and **SubnetID** with your worker node subnet's ID. To create mount targets in multiple subnets, run the command for each subnet ID. It's a best practice to create a mount target in each Availability Zone where your worker nodes are running. You can create mount targets for all the Availability Zones where worker nodes are launched. Then, all the Amazon Elastic Compute Cloud (Amazon EC2) instances in these Availability Zones can use the file system.



**Test the Amazon EFS CSI driver**

To deploy two pods that write to the same file, see [Multiple Pods Read Write Many](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/examples/kubernetes/multiple_pods>) on the GitHub website.

## Related information

[Troubleshooting Amazon EFS](<https://docs.aws.amazon.com/efs/latest/ug/troubleshooting.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
