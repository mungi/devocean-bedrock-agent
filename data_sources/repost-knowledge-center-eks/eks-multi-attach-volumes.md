Original URL: <https://repost.aws/knowledge-center/eks-multi-attach-volumes>

# How do I use Amazon EBS Multi-Attach to attach the same Volume to multiple workloads in Amazon EKS? 

I want to use Amazon Elastic Block Store (Amazon EBS) Multi-Attach for multiple workloads across multiple clusters in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

When you create a persistent workload in Amazon EKS with Amazon EBS storage, the default volume type is gp2. [Amazon EBS Multi-Attach](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes-multi.html>) allows you to attach a single Provisioned IOPS SSD (io1 or io2) volume to multiple instances in the same Availability Zone.

Amazon EBS Multi-Attach isn't supported in General Purpose SSD volumes such as gp2 and gp3. The [Amazon EBS CSI driver](<https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>) doesn't support multi-attaching volumes to workloads that run on different nodes in the same cluster.

To multi-attach the same Amazon EBS persistent storage to multiple workloads across different clusters, use Provisioned IOPS SSD volumes. Make sure that the pods run on worker nodes that are in the same Availability Zone (AZ) across the clusters.

**Note:** If your workloads are in multiple Availability Zones in the same or different clusters, then use [Amazon Elastic File System (Amazon EFS)](<https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html>). For more information, see [Create an Amazon EFS file system for Amazon EKS](<https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/efs-create-filesystem.md>) on the GitHub website.

## Resolution

Before you begin, make sure that the Amazon EBS CSI driver is installed in the required Amazon EKS clusters.  
**Note:** Multi-Attach enabled volumes can be attached to up to 16 Linux instances built on the [Nitro System](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#ec2-nitro-instances>) that are in the same Availability Zone.

To use Amazon EBS Multi-Attach to attach the same volume to multiple workloads across multiple clusters, complete the following steps.

### Provision an Amazon EBS volume

To provision an Amazon EBS volume, do the following:

  1. Provision a volume statically:
    
        aws ec2 create-volume --volume-type io2 --multi-attach-enabled --size 10 --iops 2000 --region <example-region> --availability-zone <example-az> --tag-specifications 'ResourceType=volume,Tags=[{Key=purpose,Value=prod},{Key=Name,Value=multi-attach-eks}]'

**Note:** Replace **< example-region>** with your required AWS Region. Replace **< example-az>** with your required Availability Zone.
  2. If you have an existing workload with a gp2 or gp3 volume, first create a snapshot of the volume. Then, create an io2 volume from that snapshot.   
**Note:** Amazon EBS Multi-Attach can't be turned on for io1 volumes after they're created. Amazon EBS Multi-Attach can be turned on for io2 volumes after they're created if they aren't attached to instances. For io2 dynamic storage provisioning in Amazon EKS, specify the **Immediate** mode to provision the volume without the pod to create the storage class. Make sure that you turn on Amazon EBS Multi-Attach before you create the pod.



### Retrieve the volume ID

Retrieve the volume ID that was provisioned for the workload:
    
    
    aws ec2 describe-volumes --filters "Name=tag:Name,Values=multi-attach-eks*" --query "Volumes[*].{ID:VolumeId}" --region <example-region>  

**Note:** Replace **example-region** with the required AWS Region.

### Provision a persistent workload in an existing cluster using the preceding volume ID

  1. Create the following manifest named **workloadA.yml** :
    
        apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: <example-pv-claim-name-a>
    spec:
      storageClassName: ""
      volumeName: <example-pv-name-a>
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: <example-pod-a>
    spec:
      containers:
      - name: <example-pod-container-name>
        image: centos
        command: ["/bin/sh"]
        args: ["-c", "while true; do echo $(date -u) on pod A >> /data/out.txt; sleep 15; done"]
        volumeMounts:
        - name: <example-volume-mount-name>
          mountPath: /data
      volumes:
      - name: <example-volume-mount-name>
        persistentVolumeClaim:
          claimName: <example-pv-claim-name-a>
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: <example-pv-name-a>
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 5Gi
      csi:
        driver: ebs.csi.aws.com
        fsType: ext4
        volumeHandle: <example-preceding-volume-id>
      nodeAffinity:
        required:
          nodeSelectorTerms:
            - matchExpressions:
                - key: topology.ebs.csi.aws.com/zone
                  operator: In
                  values:
                    - <example-az>

**Note:** Replace all **example** strings in the following command with your required values. Make sure that the **storageClassName** parameter value is set to empty **""** strings.

  2. Switch the kubectl context to cluster A, and then deploy the workload:
    
        kubectl config use-context <example-clusterA-context>  
    kubectl apply -f workloadA.yml




### Use the preceding volume ID to create another workload in another cluster

  1. Create and deploy the following manifest named **workloadB.yml** :
    
        apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: <example-pv-claim-name-b>
    spec:
      storageClassName: ""
      volumeName: <example-pv-name-b>
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
    ---
    apiVersion: v1
    kind: Pod
    metadata:
      name: <example-pod-b>
    spec:
      containers:
      - name: <example-pod-container-name>
        image: centos
        command: ["/bin/sh"]
        args: ["-c", "tail -f /data/out.txt"]
        volumeMounts:
        - name: <example-volume-mount-name>
          mountPath: /data
      volumes:
      - name: <example-volume-mount-name>
        persistentVolumeClaim:
          claimName: <example-pv-claim-name-b>
    
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: <example-pv-name-b>
    spec:
      accessModes:
      - ReadWriteOnce
      capacity:
        storage: 5Gi
      csi:
        driver: ebs.csi.aws.com
        fsType: ext4
        volumeHandle: <example-preceding-volume-id>
      nodeAffinity:
        required:
          nodeSelectorTerms:
            - matchExpressions:
                - key: topology.ebs.csi.aws.com/zone
                  operator: In
                  values:
                    - example-az

**Note:** Replace all **example** strings with your required values. Make sure that the **storageClassName** parameter value is set to empty **""** strings.

  2. Switch the kubectl context to cluster B, and then deploy workload:
    
        kubectl config use-context <example-clusterB-context>
    kubectl apply -f workloadB.ym

**Note** : Replace **example-clusterB-context** with your context.




### Check that the pods are running and have the same content

  1. Authenticate across the different clusters and run the following command:
    
        kubectl get pods

Example output for cluster A:
    
        NAME                          READY   STATUS    RESTARTS   AGE
    example-pod-a                 1/1     Running   0          18m  

Example output for cluster B:
    
        NAME                          READY   STATUS    RESTARTS   AGE
    example-pod-b                 1/1     Running   0          3m13s

  2. For **example-pod-a** , run the following command to view the content written to the storage:
    
        kubectl exec -it <example-pod-a> -- cat /data/out.txt

Example output:
    
        Fri Sep 22 12:39:04 UTC 2024 on example-pod-a  
    Fri Sep 22 12:39:19 UTC 2024 on example-pod-a  
    Fri Sep 22 12:39:34 UTC 2024 on example-pod-a

  3. For **example-pod-b** , run the following command to read the content written into the same storage as **example-pod-a** :
    
        kubectl logs -f <example-pod-b>

Example output:
    
        Fri Sep 22 12:39:04 UTC 2024 on example-pod-b  
    Fri Sep 22 12:39:19 UTC 2024 on example-pod-b  
    Fri Sep 22 12:39:34 UTC 2024 on example-pod-b




**Note:** Standard file systems such as XFS and EXT4 can't be accessed at the same time from multiple servers. For more information, see [Considerations and limitations](<https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volumes-multi.html#considerations>).

## Related information

[What is Amazon Elastic File System?](<https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)[Storage](<https://repost.aws/topics/TAgdRimKXeR-yBKuz9jK-Fag/storage>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)[Amazon Elastic Block Store](<https://repost.aws/tags/TAQngny0JOSqmKzdPtGiZZ2w/amazon-elastic-block-store>)

Language

English
