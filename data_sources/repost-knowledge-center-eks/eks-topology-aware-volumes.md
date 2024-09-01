Original URL: <https://repost.aws/knowledge-center/eks-topology-aware-volumes>

# How do I create and troubleshoot topology aware volume provisioning that uses an EBS CSI driver in Amazon EKS?

I want to provision topology aware volumes in an Amazon Elastic Kubernetes Service (Amazon EKS) cluster that uses Amazon Elastic Block Store (Amazon EBS) components.

## Short description

To configure and troubleshoot a cloud infrastructure topology in Amazon EKS that uses Amazon EBS components, complete the following steps:

  1. Check that the **EBS CSI** add-on is configured correctly.
  2. Configure the storage class with topology aware implementation.
  3. Create a pod and workload, and then test a topology aware scenario.
  4. Troubleshoot EBS CSI controller errors.



## Resolution

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

### Check that the EBS CSI add-on is configured correctly

**Note:** It's a best practice to use the EBS CSI provisioner **ebs.csi.aws.com** for EBS volume provisioning. Also, use the EBS CSI provisioner when implementing topology aware volumes instead of the in-tree Kubernetes provisioner **kubernetes.io/aws-ebs**.

To check that the EBS CSI add-on is configured correctly, complete the following steps:

1\. Check if the CSI driver is installed. If it isn't installed, then see [Amazon EBS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>) to install the CSI driver.

2\. Check that the AWS Identity and Access Management (IAM) role on the service account has the minimum EBS volume action permissions.

**Note:** You must annotate the service account with the IAM roles for service accounts (IRSA). If you don't annotate the service account with IRSA, then the Amazon EBS CSI driver assumes the IAM role on the worker node by default. If the CSI driver defaults to the IAM role on the worker node, then configure the required IAM role permissions in the [AWS Management Console](<https://us-east-1.console.aws.amazon.com/iam/home#/policies/arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy>).

### Configure the storage class with topology aware implementation

1\. Run the following command to deploy the storage class. Edit the manifest as needed to your specific deployment requirements.
    
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/examples/kubernetes/storageclass/manifests/storageclass.yaml

Example manifest:

**Note:** Replace the attributes in the manifest with ones that are specific to your use case.
    
    
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: ebs-sc
    provisioner: ebs.csi.aws.com
    volumeBindingMode: WaitForFirstConsumer
    parameters:
      csi.storage.k8s.io/fstype: xfs
      type: io1
      iopsPerGB: "50"
      encrypted: "true"
    allowedTopologies:
    - matchLabelExpressions:
      - key: topology.ebs.csi.aws.com/zone
        values:
        - us-east-2c

**Note:** For topology aware implementation, make sure that you configure the **allowedTopologies** option. Deleting this option causes the correct Availability Zone to be inferred and the Amazon EBS CSI controller to create a volume where the pod is scheduled.

2\. Use one of the following options to create a pv-claim:

**(Option 1)** Create a pv-claim that requests a volume with the profile type specified in the deployed storage class manifest:
    
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/examples/kubernetes/storageclass/manifests/claim.yaml

**(Option 2)** Create a pv-claim that uses an available EBS volume specified in the persistent volume manifest. Make sure to modify the option **storageClassname:** to an empty string**, "",** and modify the [nodeAffinity block](<https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/6d38a5004a83336d1368fe14602c34b92bce575a/examples/kubernetes/static-provisioning/manifests/pv.yaml#L14>) as required.
    
    
    kubectl apply -f https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/examples/kubernetes/static-provisioning/manifests

**Note:** For option 1 or option 2, if nodes aren't available in the volume's Availability Zone, then the deployment fails. This is because the scheduler can't dynamically adjust to the topology restriction.

### Create a pod and workload and test a topology aware scenario

**Create a pod**

1\. Create a test pod that uses the previous pv-claim:
    
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-ebs-csi-driver/master/examples/kubernetes/storageclass/manifests/pod.yaml

**Note:** When you use **topology.ebs.csi.aws.com/zone** in **allowedTopologies** within a storage class or persistent volume, the pod is placed in the Availability Zone that's specified in the configuration manifests. If there's no node available in that Availability Zone, then the pod gets stuck in the **Pending** state.

2\. Run the following **get** and **describe** pod commands to check the status of the deployment:
    
    
    kubectl get pod,pvc,pv
    
    
    kubectl describe pod <EXAMPLE_POD_NAME>

**Note:** Replace **EXAMPLE_POD_NAME** with your pod's name.

**Create a workload**

1\. Run the following command to create a **statefulSet** workload that uses the previous pv-claim:
    
    
    kubectl apply -f https://gist.githubusercontent.com/AbeOwlu/b8641d2f58810789986ab775f00c7780/raw/9144ae5385dfd98d4739e99983346fbdd28eaa2d/statefulset.yaml

2\. Run the following **get** and **describe** command to check the status of the **statefulSet** workload:
    
    
    kubectl get statefulset,pod,pvc,pv
    
    
    kubectl describe pod <EXAMPLE_POD_NAME>

**Note:** The **statefulSet** controller creates some pv-claims to cater to the pods' volume request for volumes in AWS Regions us-east-2b and us-east-2c. **StatefulSets** on termination isn't guaranteed to clean up persistent volumes, which could cause volumes to not be re-provisioned for **statefulSet** pods that are rescheduled to another Availability Zone.

**Test a topology aware scenario**

(Optional) To test how node replacement in another Availability Zone is handled, simulate node reshuffling by scaling down the nodes in the specified AZ. Then, scale up new nodes in another AZ. When completed, see the **Create a pod** and **Create a workload** sections.

Example output on simulated deployment issue:
    
    
    from: default-scheduler : message: 0/4 nodes are available: 1 node(s) had volume node affinity conflict, 3 node(s) had taint {eks.amazonaws.com/compute-type: fargate}, that the pod didn't tolerate.

To correct the stuck pod, scale up a node in the specified Availability Zone again to resolve the **volume node affinity conflict** error.

**Note:** When scaling up a new node in the expected Availability Zone, the deployment can fail due to failed reconciler runs. For troubleshooting steps, see the following section, **Troubleshoot EBS CSI controller errors**.

### Troubleshoot EBS CSI controller errors

Example of an EBS CSI error where pod churn and node recycle were simulated:
    
    
    from: default-scheduler : message: 0/5 nodes are available: 1 node(s) didn't find available persistent volumes to bind, 1 node(s) didn't match Pod's node affinity/selector, 3 node(s) had taint {eks.amazonaws.com/compute-type: fargate}, that the pod didn't tolerate

1\. To isolate the issue, describe the pod, and review the error log entries in the event. In the preceding example error, the message shows that four of five nodes can't be scheduled due to node taints and topology or affinity configuration. Also, the last node running in the correct Availability Zone didn't find an available persistent volume to bind.

2\. To isolate this issue, check the status of the pv-claim bind:
    
    
    kubectl describe persistentvolumeclaim <PVC_NAME>

**Note:** The pv-claim statuses are **waiting** , **bound** , **invalid** , or **not found**. In the following example, the pv-claim is waiting for the driver to create a volume. As it waits, the pv-claim doesn't bind to a target node.
    
    
    `from: ebs.csi.aws.com_ebs-csi-controller- : message:  failed to get target node: node "ip-10-0-60-85.ec2.internal" not found`  
    `waiting for a volume to be created, either by external provisioner "ebs.csi.aws.com" or manually created by system administrator`

3\. Check the **csi-provisioner** container logs in the **ebs-csi-controller** pod:
    
    
    kubectl logs ebs-csi-controller-<RANDOM_HASH> -c csi-provisioner -n kube-system

The following output is an example error event:
    
    
    Retrying syncing claim "claim-id", failure 343 error syncing claim "claim-id": failed to get target node: node "ip-10-0-60-85.ec2.internal" not found

**Note:** If error events similar to the preceding message occur, then the pv-claim reconciler failed to find a **selected target node** annotation. Remove this annotation so that the pv-claim can successfully sync.

4\. To remove the **selected target node** annotation, run the following command. Make sure to copy and save the output into the pv-claim manifest to remove the **selected-node** annotation.
    
    
    kubectl edit  persistentvolumeclaims ebs-claim | grep -v "volume.kubernetes.io/selected-node:"

If the proceeding troubleshooting steps don't resolve your issue, then gather the logs from the isolated container workload and contact AWS Support. You can also search for related issues on the [GitHub repository](<https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fkubernetes-sigs%2Faws-ebs-csi-driver%2Fissues%2Fnew%2Fchoose>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
