Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-efs-volume-mount-issues>

# How do I troubleshoot issues with my Amazon EFS volume mounts in Amazon EKS?

I want to troubleshoot errors when mounting Amazon Elastic File System (Amazon EFS) volumes in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Resolution

When you mount your Amazon EFS volume in your Amazon EKS cluster, you might get one of the following errors in your pods:

  * "Output: mount.nfs4: mounting fs-18xxxxxx.efs.us-east-1.amazonaws.com:/path-in-dir:/ failed, reason given by server: No such file or directory"
  * "Output: Failed to resolve "fs-xxxxxx.efs.us-west-2.amazonaws.com" - check that your file system ID is correct"
  * "mount.nfs4: access denied by server while mounting 127.0.0.1:/"
  * "mount.nfs: Connection timed out"
  * "Unable to attach or mount volumes: timed out waiting for the condition"



Before you begin the troubleshooting steps, verify that you have the following prerequisites:

  * An [Amazon EFS file system](<https://docs.aws.amazon.com/efs/latest/ug/creating-using-create-fs.html>) created with a [mount target](<https://docs.aws.amazon.com/efs/latest/ug/accessing-fs.html>) in each of the worker node subnets.
  * A valid [EFS storage class](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/dynamic_provisioning/specs/storageclass.yaml>) (from the GitHub website) definition using the **efs.csi.aws.com** provisioner.
  * A valid [PersistentVolumeClaim](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/encryption_in_transit/specs/claim.yaml>) (PVC) definition and [PersistentVolume](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/encryption_in_transit/specs/pv.yaml>) definition. This isn't needed if you're using [dynamic provisioning](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/examples/kubernetes/dynamic_provisioning>) (from the GitHub website).
  * The [Amazon EFS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html#efs-install-driver>) installed in the cluster.



### Verify that the mount targets are configured correctly

Be sure to create the EFS mount targets in each Availability Zone where the EKS nodes are running. For example, suppose that your worker nodes are spread across **us-east-1a** and **us-east-1b**. In this case, create mount targets in both Availability Zones for the EFS file system that you want to mount. If you don't correctly create the mount targets, then the pods that are mounting the EFS file system return an error similar to the following message:

"Output: Failed to resolve "fs-xxxxxx.efs.us-west-2.amazonaws.com" - check that your file system ID is correct."

### Verify that the security group associated with your EFS file system and worker nodes allows NFS traffic

Your EFS file system's [security group](<https://docs.aws.amazon.com/efs/latest/ug/accessing-fs-create-security-groups.html>) must have [an inbound rule](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html#adding-security-group-rules>) that allows NFS traffic from the CIDR for your cluster's VPC. Allow port 2049 for inbound traffic.

The security group that's associated with your worker nodes where the pods are failing to mount the EFS volume [must have an outbound rule](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html#adding-security-group-rules>). Specifically, this outbound rule must allow NFS traffic (port 2049) to the EFS file system.

If the security group doesn't allow NFS traffic, then the pods that are mounting the file system return the following errors:

  * "mount.nfs: Connection timed out"
  * "Unable to attach or mount volumes: timed out waiting for the condition"



### Verify that the subdirectory is created in your EFS file system if you're mounting the pod to a subdirectory

When you add sub paths in persistent volumes, the EFS CSI driver doesn't create the subdirectory path in the file system. The directories must be already present for the mount operation to succeed. If the sub path isn't present in the file system, then the pods fail with the following error:

"Output: mount.nfs4: mounting fs-18xxxxxx.efs.us-east-1.amazonaws.com:/path-in-dir:/ failed, reason given by server: No such file or directory"

### Confirm that the cluster's VPC uses the Amazon DNS server

When you mount the EFS with the EFS CSI driver, the EFS mount helper requires that you use the [Amazon DNS server](<https://docs.aws.amazon.com/vpc/latest/userguide/VPC_DHCP_Options.html#AmazonDNS>) for the VPC.

**Note:** The EFS service’s file system DNS has an AWS architectural limitation. Only the Amazon provided DNS can resolve the EFS service's file system DNS.

To verify the DNS server, log in to the worker node and run the following command:
    
    
    nslookup fs-4fxxxxxx.efs.region.amazonaws.com AMAZON\_PROVIDED\_DNS\_IP
    

**Note:** Replace **region** with your AWS Region. Replace AMAZON_PROVIDED_DNS_IP with your DNS IP address. By default, this is the VPC network range (10.0.0.0) plus two.

If the cluster VPC uses a custom DNS server, then configure this DNS server to forward all ***.amazonaws.com** requests to the Amazon DNS server. If these requests aren't forwarded, then the pods fail with an error similar to the following message:

"Output: Failed to resolve "fs-4 fxxxxxx.efs.us-west-2.amazonaws.com" - check that your file system ID is correct."

### Verify that you have "iam" mount options in the persistent volume definition when using a restrictive file system policy

In some cases, the EFS file system policy is configured to restrict mount permissions to specific IAM roles. In this case, the EFS mount helper requires that the [-o iam](<https://docs.aws.amazon.com/efs/latest/ug/mounting-IAM-option.html>) mount option pass during the mount operation. Include the **spec.mountOptions** property to allow the CSI driver to add the [iam mount option](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/issues/280>) (from the GitHub website).

The following example is a **PersistentVolume** specification:
    
    
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: efs-pv1
    spec:
      mountOptions:
        - iam
    . . . . . .

If you don't add the **iam** mount option with a restrictive file system policy, then the pods fail with an error similar to following message:

"mount.nfs4: access denied by server while mounting 127.0.0.1:/"

### Verify that the Amazon EFS CSI driver controller service account is annotated with the correct IAM role and the IAM role has the required permissions

To verify that the service account that the [efs-csi-controller](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html#efs-create-iam-resources>) pods use has the correct annotation, run the following command:
    
    
    kubectl describe sa efs-csi-controller-sa -n kube-system

Verify that the following annotation is present:
    
    
    eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/AmazonEKS\_EFS\_CSI\_DriverRole

Verify that you completed the following steps:

  * You created the [IAM OIDC provider](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>) for the cluster.
  * The IAM role that's associated with **efs-csi-controller-sa** service account has the required [permissions](<https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json>) (from the GitHub website) to perform EFS API calls.
  * The IAM role's trust policy trusts the service account **efs-csi-controller-sa**. The IAM role's trust policy must look like the following example:


    
    
    {
    	"Version": "2012-10-17",
    	"Statement": \[{
    		"Effect": "Allow",
    		"Principal": {
    			"Federated": "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
    		},
    		"Action": "sts:AssumeRoleWithWebIdentity",
    		"Condition": {
    			"StringEquals": {
    				"oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
    			}
    		}
    	}\]
    }

### Verify that the EFS CSI driver pods are running

The EFS CSI driver is made up of controller pods that are run as a deployment and node pods that are run as a DaemonSet. To verify that these pods are running in your cluster, run the following command:
    
    
    kubectl get all -l app.kubernetes.io/name=aws-efs-csi-driver -n kube-system

### Verify the EFS mount operation from the EC2 worker node where the pod is failing to mount the file system

Log in to the Amazon EKS worker node where the pod is scheduled. Then, use the [EFS mount helper](<https://docs.aws.amazon.com/efs/latest/ug/efs-mount-helper.html#mounting-fs-mount-helper-ec2-linux>) to try to manually mount the EFS file system to the worker node. To test the mount operation, run the following command:
    
    
    sudo mount -t -efs -o tls file-system-dns-name efs-mount-point/

If the worker node can mount the file system, then review the **efs-plugin** logs from the CSI controller and CSI node pods.

### Check the EFS CSI driver pod logs

Check the CSI driver pod logs to determine the cause of the mount failures. If the volume is failing to mount, then review the **efs-plugin** logs. To retrieve the **efs-plugin** container logs, run the following commands :
    
    
    kubectl logs deployment/efs-csi-controller -n kube-system -c efs-plugin
    kubectl logs daemonset/efs-csi-node -n kube-system -c efs-plugin

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
