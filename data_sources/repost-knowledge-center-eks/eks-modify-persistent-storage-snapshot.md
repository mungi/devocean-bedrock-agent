Original URL: <https://repost.aws/knowledge-center/eks-modify-persistent-storage-snapshot>

# How do I restore, resize, or create an EBS persistent storage snapshot in Amazon EKS for disaster recovery or when the EBS modification rate is exceeded?

I want to use an Amazon Elastic Block Store (Amazon EBS) persistent storage snapshot in Amazon Elastic Kubernetes Service (Amazon EKS) for disaster recovery. How do I create, resize, or restore such a snapshot? Or, I exceeded my Amazon EBS modification rate. But I still need to resize, restore, or create a snapshot of my Amazon EBS persistent storage in Amazon EKS.

## Short description

You're modifying your Amazon EBS persistent storage in Amazon EKS, and you receive the following error:

**errorCode: Client.VolumeModificationRateExceeded  
errorMessage: You've reached the maximum modification rate per volume limit. Wait at least 6 hours between modifications per EBS volume**

After you modify a volume, you must wait at least six hours before you can continue to modify the volume. Make sure that the volume is in the **in-use** or **available** state before you modify it again.

Your organization might have a [Disaster Recovery (DR) objective](<https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/disaster-recovery-dr-objectives.html>) with a Recovery Time Objective (RTO) that's less than six hours. For RTOs that are less than six hours, create a snapshot and restore your volume using the [Amazon EBS Container Storage Interface (CSI) driver](<https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html>).

## Resolution

**Note:** If you receive errors when running AWS Command Line Interface (AWS CLI) commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>).

Use the Amazon EBS CSI driver and external snapshotter to do the following:

  1. Create an Amazon EBS snapshot of the **PersistentVolumeClaim**.
  2. Restore the **PersistentVolumeClaim**.
  3. Bind the **PersistentVolumeClaim** to the workload.



Pre-requisites:

  * An existing Amazon EKS cluster with worker nodes. If you don't have one, then [create your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-create-cluster>).
  * The latest versions of AWS CLI, [eksctl](<https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html>), and [kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>).
  * [An Amazon EBS CSI driver AWS Identity and Access Management (IAM) role for service accounts](<https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html>).



### Install the Amazon EBS CSI driver with the external snapshotter

1\. Check if you have an existing IAM OpenID Connect (OIDC) provider for your cluster:
    
    
    % cluster_name=ebs
    % oidc_id=$(aws eks describe-cluster --name cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
    % aws iam list-open-id-connect-providers | grep $oidc_id

**Note:** Replace **cluster_name** with your cluster's name.

Example output:
    
    
    "Arn": "arn:aws:iam::XXXXXXXXXX:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/B7E2BC2980D17C9A5A3889998CB22B23"

**Note:** If you don't have an IAM OIDC provider, then [create one for your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>).

2\. Install the external snapshotter.  
**Note:** You must install the external snapshotter before you install the Amazon EBS CSI add-on. Also, you must install the external snapshotter components in the following order:

**CustomResourceDefinition** (CRD) for **volumesnapshotclasses** , **volumesnapshots** , and **volumesnapshotcontents**
    
    
    mkdir crd
    cd crd
    wget https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/kustomization.yaml
    wget https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
    wget https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
    wget https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
    kubectl apply -k ../crd

**RBAC** , such as **ClusterRole** , and **ClusterRoleBinding**
    
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml

**Controller deployment**
    
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml

3\. Create your Amazon EBS CSI plugin IAM role using **eksctl** :
    
    
    eksctl create iamserviceaccount \
      --name ebs-csi-controller-sa \
      --namespace kube-system \
      --cluster cluster_name \
      --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
      --approve \
      --role-only \
      --role-name AmazonEKS_EBS_CSI_DriverRole

4\. Add the Amazon EBS CSI add-on using **eksctl** :
    
    
    eksctl create addon --name aws-ebs-csi-driver --cluster cluster_name --service-account-role-arn arn:aws:iam::account_id:role/AmazonEKS_EBS_CSI_DriverRole --force

**Note:** Replace **account_id** with your AWS account ID.

5\. Confirm that the Amazon EBS CSI driver and external snapshotter pods are running:
    
    
    % kubectl get pods -A | egrep "csi|snapshot"

### Create a StatefulSet with Amazon EBS persistent storage

1\. [Download the manifests](<https://github.com/aws-samples/aws-eks-se-samples/tree/main/knowledge-center/how-to-snapshot-restore-resize-sts>) from the GitHub website.

2\. Create the **StorageClass** and **VolumeSnapshotClass** :
    
    
    % kubectl apply -f manifests/classes/

Example output:
    
    
    volumesnapshotclass.snapshot.storage.k8s.io/csi-aws-vsc created
    storageclass.storage.k8s.io/ebs-sc created

3\. Deploy the StatefulSet on your cluster along with the **PersistentVolumeClaim** :
    
    
    % kubectl apply -f manifests/app/

Example output:
    
    
    service/cassandra created
    StatefulSet.apps/cassandra created

4\. Verify that the pods are in **Running** status:
    
    
    % kubectl get pods

Example output:
    
    
    NAME         READY  STATUS   RESTARTS  AGE
    cassandra-0  1/1    Running  0         33m
    cassandra-1  1/1    Running  0         32m
    cassandra-2  1/1    Running  0         30m

5\. Verify that the **PersistenVolumeClaim** is bound to your **PersisentVolume** :
    
    
    % kubectl get pvc

Example output:
    
    
    NAME                                              STATUS  VOLUME                                    CAPACITY ACCESS MODES STORAGECLASS  AGE
    
    persistentvolumeclaim/cassandra-data-cassandra-0  Bound   pvc-b3ab4971-37dd-48d8-9f59-8c64bb65b2c8  2Gi      RWO          ebs-sc        28m
    persistentvolumeclaim/cassandra-data-cassandra-1  Bound   pvc-6d68170e-2e51-40f4-be52-430790684e51  2Gi      RWO          ebs-sc        28m
    persistentvolumeclaim/cassandra-data-cassandra-2  Bound   pvc-d0403adb-1a6f-44b0-9e7f-a367ad7b7353  2Gi      RWO          ebs-sc        26m
    ...

**Note:** Note the names of each **PersistentVolumeClaim** to compare to the **PersistentVolumeClaim** names in the snapshot manifest.

6\. To test the StatefulSet, write content to the **PersistentVolumeClaim** :
    
    
    for i in {0..2}; do kubectl exec "cassandra-$i" -- sh -c 'echo "$(hostname)" > /cassandra_data/data/file.txt'; done

### Create a snapshot

The **persistentVolumeClaimName** in the snapshot manifest must match the name of the **PersistentVolumeClaim** that you created for each pod in the StatefulSet. For example:
    
    
    apiVersion: snapshot.storage.k8s.io/v1
    kind: VolumeSnapshot
    metadata:
      name: cassandra-data-snapshot-0
    spec:
      volumeSnapshotClassName: csi-aws-vsc
      source:
        persistentVolumeClaimName: cassandra-data-cassandra-0

1\. Create a snapshot from each **PersistenVolumeClaim** :
    
    
    % kubectl apply -f manifests/snapshot/

Example output:
    
    
    volumesnapshot.snapshot.storage.k8s.io/cassandra-data-snapshot-0 created
    volumesnapshot.snapshot.storage.k8s.io/cassandra-data-snapshot-1 created
    volumesnapshot.snapshot.storage.k8s.io/cassandra-data-snapshot-2 created

2\. After the state is completed, verify that the snapshots are available on the Amazon Elastic Compute Cloud (Amazon EC2) console:
    
    
    aws ec2 describe-snapshots --filters "Name=tag-key,Values=*ebs*" --query 'Snapshots[*].{VOL_ID:VolumeId,SnapshotID:SnapshotId,State:State,Size:VolumeSize,Name:[Tags[?Key==`Name`].Value] [0][0]}' --output table
    ---------------------------------------------------------------------------------------------------------------------------------------
    |                                                          DescribeSnapshots                                                          |
    +------------------------------------------------------------+-------+-------------------------+------------+-------------------------+
    |                            Name                            | Size  |       SnapshotID        |   State    |         VOL_ID          |
    +------------------------------------------------------------+-------+-------------------------+------------+-------------------------+
    |  ebs-dynamic-snapshot-c6c9cb3c-2dab-4833-9124-40a0abde170d |  2    |  snap-057c5e2de3957d855 |  pending   |  vol-01edf53ee26a615f5  |
    |  ebs-dynamic-snapshot-1c1ad0c5-a93a-468f-ab54-576db5d630d4 |  2    |  snap-02bf49a3b78ebf194 |  completed |  vol-0289efe54525dca4a  |
    |  ebs-dynamic-snapshot-760c48e7-33ff-4b83-a6fb-6ef13b8d31b7 |  2    |  snap-0101c3d2efa40af19 |  completed |  vol-0fe68c9ac2f6375a4  |
    +------------------------------------------------------------+-------+-------------------------+------------+-------------------------+

### Restore the snapshot

You can restore a **PersistentVolumeClaim** from a snapshot that's created from an existing **PersistentVolumeClaim** using the same name of the **PersistentVolumeClaim**. When you recreate the StatefulSet, the **PersistentVolumeClaim** dynamically provisions a **PersistentVolume** and is automatically bound to the StatefulSet pods. The StatefulSet **PersistenVolumeClaim** name format is: `PVC\_TEMPLATE\_NAME-STATEFULSET\_NAME-REPLICA\_INDEX`.

To restore a snapshot follow these steps:

1\. Delete the existing StatefulSet workload:
    
    
    kubectl delete -f manifests/app/Cassandra_statefulset.yaml

**Note:** Deleting the workload also deletes the StatefulSet pods. The snapshot that you created acts as a backup.

Example output:
    
    
    statefulset.apps "cassandra" deleted

2\. Forcefully delete the **PersistentVolumeClaim** :
    
    
    for i in {0..2}
    do
      kubectl delete pvc cassandra-data-cassandra-$i --force
    done

**Note:** Deleting the **PersistentVolumeClaim** also deletes the **PersistentVolume**.

3\. Restore the **PersistentVolumeClaim** from the snapshot using the same name of the **PersistentVolumeClaim** that you created:
    
    
    kubectl apply -f manifests/snapshot-restore/

Example output:
    
    
    persistentvolumeclaim/cassandra-data-cassandra-0 created
    persistentvolumeclaim/cassandra-data-cassandra-1 created
    persistentvolumeclaim/cassandra-data-cassandra-2 created

4\. Verify that each **PersistentVolumeClaim** is in **Pending** status:
    
    
    kubectl get pvc

Example output:
    
    
    NAME                         STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
    cassandra-data-cassandra-0   Pending                                      ebs-sc         24s
    cassandra-data-cassandra-1   Pending                                      ebs-sc         23s
    cassandra-data-cassandra-2   Pending                                      ebs-sc         22s

5\. Recreate the StatefulSet with the original manifest:
    
    
    kubectl apply -f manifests/app-restore/

**Note:** To resize the storage, define the StatefulSet with a new storage size.

Example output:
    
    
    StatefulSet.apps/cassandra created

6\. Check the content of the Amazon EBS storage to confirm that the snapshot and restore work:
    
    
    for i in {0..2}; do kubectl exec "cassandra-$i" -- sh -c 'cat /cassandra_data/data/file.txt'; done
    cassandra-0
    cassandra-1
    cassandra-2

### Resize the PersistentVolumeClaim

You can modify the **.spec.resources.requests.storage** of the **PersistentVolumeClaim** to automatically reflect the size that you defined in the StatefulSet manifest:
    
    
    for i in {0..2}
    do
      echo "Resizing cassandra-$i"
      kubectl patch pvc cassandra-data-cassandra-$i -p '{ "spec": { "resources": { "requests": { "storage": "4Gi" }}}}'
    done

**Note:** **4Gi** is an example storage size. Define a storage size that's suitable for your use case.

Confirm that the new storage size is reflected on the Amazon EC2 console and in the pods:
    
    
    % aws ec2 describe-volumes --filters "Name=tag-key,Values=*pvc*" --query 'Volumes[*].{ID:VolumeId,Size:Size,Name:[Tags[?Key==`Name`].Value] [0][0]}' --output table
    -------------------------------------------------------------------------------------------
    |                                     DescribeVolumes                                     |
    +------------------------+--------------------------------------------------------+-------+
    |           ID           |                         Name                           | Size  |
    +------------------------+--------------------------------------------------------+-------+
    |  vol-01266a5f1f8453e06 |  ebs-dynamic-pvc-359a87f6-b584-49fa-8dd9-e724596b2b43  |  4    |
    |  vol-01b63a941450342d9 |  ebs-dynamic-pvc-bcc6f2cd-383d-429d-b75f-846e341d6ab2  |  4    |
    |  vol-041486ec92d4640af |  ebs-dynamic-pvc-fa99a595-84b7-49ad-b9c2-1be296e7f1ce  |  4    |
    +------------------------+--------------------------------------------------------+-------+
    
    % for i in {0..2}
    do
      echo "Inspecting cassandra-$i"
      kubectl exec -it cassandra-$i -- lsblk
      kubectl exec -it cassandra-$i -- df -h
    done...

### Run the following Kubectl commands to clean up your StatefulSet

To delete the resources that you created for your StatefulSet, run the following **kubectl** commands:

**app-restore**
    
    
    kubectl delete -f manifests/app-restore

**snapshot-restore**
    
    
    kubectl delete -f manifests/snapshot-restore

**snapshot**
    
    
    kubectl delete -f manifests/snapshot

**classes**
    
    
    kubectl delete -f manifests/classes

**Cassandra**
    
    
    kubectl delete -f manifests/app/Cassandra_service.yaml

* * *

## Related information

[ModifyVolume](<https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_ModifyVolume.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
