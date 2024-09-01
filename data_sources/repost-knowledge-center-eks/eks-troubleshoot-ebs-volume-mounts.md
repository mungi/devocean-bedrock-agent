Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-ebs-volume-mounts>

# How do I troubleshoot issues with my EBS volume mounts in Amazon EKS?

I want to mount Amazon Elastic Block Store (Amazon EBS) volumes in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster. However, I receive a "Timeout expired waiting for volumes to attach or mount for pod" error.

## Resolution

Before you begin troubleshooting, verify that you have the following prerequisites:

  * The required AWS Identity and Access Management (IAM) permissions for your [ebs-csi-controller-sa service account IAM role](<https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html>).  
**Note:** To troubleshoot issues with your service account, see the section **Check the Amazon EBS CSI driver controller service account's IAM role and the role's permissions**.
  * A valid [PersistentVolumeClaim](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/examples/kubernetes/dynamic-provisioning/manifests/claim.yaml>) (PVC) (from the GitHub website) in the same namespace as the pod.
  * A valid EBS storage class definition that uses the in-tree provisioner [kubernetes.io/aws-ebs](<https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs>) (from the Kubernetes website). Or, a storage class definition that uses the EBS Container Storage Interface (CSI) driver provisioner [ebs.csi.aws.com](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/examples/kubernetes/dynamic-provisioning/manifests/storageclass.yaml>) (from the GitHub website).



### Verify that the Amazon EBS CSI driver controller and node pods are running

The [EBS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>) consists of controller pods that run as a deployment and node pods that run as a daemon set. To check if your cluster runs these pods, run the following command:
    
    
    kubectl get all -l app.kubernetes.io/name=aws-ebs-csi-driver -n kube-system

**Note:** Windows worker nodes and AWS Fargate don't support the EBS CSI driver.

Make sure that the installed [EBS CSI driver version is compatible with your cluster's Kubernetes version](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver#kubernetes-version-compatibility-matrix>) (from the GitHub website).

### Check if the PVC encountered issues when binding to the EBS persistent volume

To check if the PVC encounters issues, run the following command to view events. In the following example command, replace **PVC_NAME** and **NAMESPACE** with the correct values for your environment:
    
    
    kubectl describe pvc PVC_NAME -n NAMESPACE

If you use dynamic volume provisioning, then review the returned events to determine if volume provisioning succeeded or failed. You can also see the corresponding persistent volume name that the PVC is bound to, as shown in the following example:
    
    
    Name:          ebs-claim
    Namespace:     default
    StorageClass:  ebs-sc
    Status:        Bound
    Volume:        pvc-5cbd76de-6f15-41e4-9948-2bba2574e205
    Annotations:   pv.kubernetes.io/bind-completed: yes
                   pv.kubernetes.io/bound-by-controller: yes
                   volume.beta.kubernetes.io/storage-provisioner: ebs.csi.aws.com
                   volume.kubernetes.io/selected-node: ip-10-0-2-57.ec2.internal
    . . . . .
    . . . . . 
    Events:
      Type    Reason                 Age                    From                                                                                      Message
      ----    ------                 ----                   ----                                                                                      -------
    . . . . .
      Normal  Provisioning           5m22s                  ebs.csi.aws.com_ebs-csi-controller-57d4cbb9cc-dr9cd_8f0373e8-4e58-4dd0-b83c-da6f9ad5d5ce  External provisioner is provisioning volume for claim "default/ebs-claim"
      Normal  ProvisioningSucceeded  5m18s                  ebs.csi.aws.com_ebs-csi-controller-57d4cbb9cc-dr9cd_8f0373e8-4e58-4dd0-b83c-da6f9ad5d5ce  Successfully provisioned volume pvc-5cbd76de-6f15-41e4-9948-2bba2574e205

If the provisioning failed, then find the error message in events.

### Review the Amazon EBS CSI controller pods' logs

To see the cause of the mount failures, check the controller pod logs. If the volume fails during creation, then refer to the **ebs-plugin** and **csi-provisioner** logs. To retrieve the **ebs-plugin** container logs, run the following commands:
    
    
    kubectl logs deployment/ebs-csi-controller -n kube-system -c ebs-plugin
    
    
    kubectl logs daemonset/ebs-csi-node -n kube-system -c ebs-plugin

To retrieve the **csi-provisioner** container logs, run the following command:
    
    
    kubectl logs deployment/ebs-csi-controller -n kube-system -c csi-provisioner

If the EBS volumes fail to attach to the pod, then review the **csi-attacher** logs. To retrieve the **csi-attacher** container logs, run the following command:
    
    
    kubectl logs deployment/ebs-csi-controller -n kube-system -c csi-attacher

### Check the Amazon EBS CSI driver controller service account's IAM role and the role's permissions

**Note:** To increase debugging efficiency of the EBS CSI driver, set the [debug log options](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/options.md>) (from the GitHub website).

Make sure that the EBS CSI driver controller service account is annotated with the correct IAM role. Also, make sure that the IAM role has the required permissions.

The following issues result in **unauthorized** errors in your PVC events or in your **ebs-csi-controller** logs:

  * Missing permissions in the IAM role.
  * An incorrect [IAM role that's associated with the service account](<https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html>).



1\. To determine if the **ebs-csi-controller** pods' service account has the correct annotation, run the following command:
    
    
    kubectl describe sa ebs-csi-controller-sa -n kube-system

2\. Verify that the following annotation is present:
    
    
    eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/AmazonEKS_EBS_CSI_DriverRole

3\. Verify that you created the [IAM OpenID Connect (OIDC) provider](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>) for the cluster. Also, verify that the IAM role has the required [permissions](<https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html>) to perform EBS API calls. Make sure that the IAM role's trust policy trusts the service account **ebs-csi-controller-sa**.

3\. Verify that AWS CloudTrail makes the **CreateVolume** , **AttachVolume** , and **DetachVolume** calls. To do this, review the CloudTrail logs. Also, review the logs to determine which principal makes the calls. This helps you determine if the controller or the worker node IAM role uses the service account IAM role.

### Verify the persistent volume's node affinity

Each persistent volume has a node affinity that limits the attachment of persistent volumes to nodes within a single Availability Zone. This is because you can attach EBS volumes only to pods or nodes that run in the same Availability Zone that you created them in. If the scheduled pods for nodes in one Availability Zone use the EBS persistent volume in a different Availability Zone, then you receive this error:

"FailedScheduling: 1 node(s) had volume node affinity conflict"

To avoid this, use [StatefulSets](<https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/>) (from the Kubernetes website) instead of deployment. This creates a unique EBS volume for each pod of the StatefulSets in the same Availability Zone as the pod.

To verify the persistent volume's node affinity, run the following command. Replace **PERSISTENT_VOLUME_NAME** with your volume's name:
    
    
    kubectl describe pv PERSISTENT_VOLUME_NAME

**Note:** You can't mount an EBS volume to two different pods that run on two different worker nodes. You can attach the EBS volume to pods that run on one node, but you can't attach it to another node at the same time. If you try to attach your EBS volume to two pods on different worker nodes, then the pod fails and you receive this error:

"Warning FailedAttachVolume 2m38s attachdetach-controller Multi-Attach error for volume "pvc-1cccsdfdc8-fsdf6-43d6-a1a9-ea837hf7h57fa" Volume is already exclusively attached to one node and can't be attached to another"

### Make sure that your EBS controller pods have connectivity to the Amazon Elastic Compute Cloud (Amazon EC2) API

If you see errors for connection timeouts in the **ebs-csi-controller** logs, then the EBS CSI controller might not be connected to the Amazon EC2 API. If the controller pods have connectivity issues when you create your PVC, then you see this error:

"Warning ProvisioningFailed persistentvolumeclaim/storage-volume-1 failed to provision volume with StorageClass "ebs-sc": rpc error: code = DeadlineExceeded desc = context deadline exceeded"

To resolve this error, check that the EBS controller pods' subnets have connectivity to EC2 API. If you run a [private cluster with an HTTP/HTTPS proxy](<https://repost.aws/knowledge-center/eks-http-proxy-configuration-automation>), then verify that your EBS CSI controller pods can use the HTTP/HTTPS proxy. EBS CSI driver's helm installation [supports setup of an HTTP/HTTPS proxy](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/charts/aws-ebs-csi-driver/values.yaml#L59>) (from the Kubernetes website).

This message might also relate to an issue with OIDC. To trouble OIDC issues, see [How do I troubleshoot an OIDC provider and IRSA in Amazon EKS?](<https://repost.aws/knowledge-center/eks-troubleshoot-oidc-and-irsa>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
