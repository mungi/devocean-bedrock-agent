Original URL: <https://repost.aws/knowledge-center/eks-pods-encryption-efs>

# How do I mount an encrypted Amazon EFS file system to a pod in Amazon EKS?

I want to mount an encrypted Amazon Elastic File System (Amazon EFS) file system to a pod in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

You can encrypt your data either [in transit with TLS](<https://docs.aws.amazon.com/efs/latest/ug/encryption-in-transit.html>) or [at rest](<https://docs.aws.amazon.com/efs/latest/ug/encryption-at-rest.html>).

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

## Resolution

### Encrypt data in transit with TLS

To encrypt your data in transit with TLS, complete the following steps:

  1. [Deploy the Amazon EFS Container Storage Interface (CSI) driver](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>) for your Amazon EKS cluster.

  2. [Create an Amazon EFS file system](<https://docs.aws.amazon.com/efs/latest/ug/gs-step-two-create-efs-resources.html>) without encryption for your cluster.  
**Note:** When you create the file system, [create a mount target](<https://docs.aws.amazon.com/efs/latest/ug/accessing-fs.html>) for Amazon EFS in all Availability Zones where your EKS nodes are located. 

  3. Clone the GitHub repository to your local system:
    
        git clone https://github.com/kubernetes-sigs/aws-efs-csi-driver.git

  4. Go to the **encryption_in_transit** example directory:
    
        cd aws-efs-csi-driver/examples/kubernetes/encryption_in_transit/

  5. Retrieve your Amazon EFS file system ID:
    
        aws efs describe-file-systems --query "FileSystems[*].FileSystemId" --output text

  6. Go to the **pv.yaml** file in the **/examples/kubernetes/encryption_in_transit/specs/** directory. Then, replace the value of **VolumeHandle** with the **FileSystemId** of the Amazon EFS file system that you're mounting. For example:
    
        apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: efs-pv
    spec:
      capacity:
        storage: 5Gi
      volumeMode: Filesystem
      accessModes:
        - ReadWriteOnce
      persistentVolumeReclaimPolicy: Retain
      storageClassName: efs-sc
      csi:
        driver: efs.csi.aws.com
        volumeHandle: [FileSystemId]
        volumeAttributes:
          encryptInTransit: "true"

**Note:** The **volumeAttributes: encryptInTransit** mount option activates encryption in transit.

  7. Deploy the storage class, persistent volume claim, persistent volume, and pod from the **/examples/kubernetes/encryption_in_transit/specs/** directory:
    
        kubectl apply -f specs/storageclass.yaml
    kubectl apply -f specs/pv.yaml
    kubectl apply -f specs/claim.yaml
    kubectl apply -f specs/pod.yaml

  8. Verify that your pod is in a running state:
    
        kubectl get pods

  9. List the persistent volumes in the default namespace:
    
        kubectl get pv

  10. Describe the persistent volume:
    
        kubectl describe pv efs-pv

**Note:** The Amazon EFS file system ID is listed as the **VolumeHandle**.

  11. Verify that the data is written onto the Amazon EFS file system:
    
        kubectl exec -ti efs-app -- tail -f /data/out.txt




### Encrypt data at rest

To encrypt data at rest, complete the following steps:

  1. [Deploy the Amazon EFS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>) for your Amazon EKS cluster.

  2. Turn on [encryption at rest](<https://docs.aws.amazon.com/efs/latest/ug/encryption-at-rest.html>) for your Amazon EKS cluster to create an Amazon EFS file system.

  3. Clone the following GitHub repository to your local system:
    
        git clone https://github.com/kubernetes-sigs/aws-efs-csi-driver.git

  4. Go to the **multiple_pods** example directory:
    
        cd aws-efs-csi-driver/examples/kubernetes/multiple_pods/

  5. Retrieve your Amazon EFS file system ID:
    
        aws efs describe-file-systems

Example output:
    
        { "FileSystems": [
     {
     "SizeInBytes": {
     "Timestamp": ,
     "Value":
     },
     "ThroughputMode": "",
     "CreationToken": "",
     "Encrypted": true,
     "CreationTime": ,
     "PerformanceMode": "",
     "FileSystemId": "[FileSystemId]",
     "NumberOfMountTargets": ,
     "LifeCycleState": "available",
     "KmsKeyId": "arn:aws:kms:ap-southeast-1:<account_id>:key/854df848-fdd1-46e3-ab97-b4875c4190e6",
     "OwnerId": ""
     },
     ]
    }

  6. Go to the **pv.yaml** file in the **/examples/kubernetes/multiple_pods/specs/** directory. Then, replace the value of **volumeHandle** with the **FileSystemId** of the Amazon EFS file system that you're mounting. For example:
    
        apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: efs-pv
    spec:
      capacity:
        storage: 5Gi
      volumeMode: Filesystem
      accessModes:
        - ReadWriteMany
      persistentVolumeReclaimPolicy: Retain
      storageClassName: efs-sc
      csi:
        driver: efs.csi.aws.com
        volumeHandle: [FileSystemId]

  7. Deploy the storage class, persistent volume claim, persistent volume, and pod from the **/examples/kubernetes/multiple_pods/specs/** directory:
    
        kubectl apply -f specs/storageclass.yaml  
    kubectl apply -f specs/pv.yaml 
    kubectl apply -f specs/claim.yaml 
    kubectl apply -f specs/pod1.yaml 
    kubectl apply -f specs/pod2.yaml

  8. Verify that your pod is in a running state:
    
        kubectl get pods

  9. List the persistent volumes in the default namespace:
    
        kubectl get pv

  10. Describe the persistent volume:
    
        kubectl describe pv efs-pv

  11. Verify that the data is written onto the Amazon EFS file system:
    
        kubectl exec -ti app1 -- tail /data/out1.txt
    kubectl exec -ti app2 -- tail /data/out1.txt




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
