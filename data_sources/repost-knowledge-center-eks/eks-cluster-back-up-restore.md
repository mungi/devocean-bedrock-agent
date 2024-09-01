Original URL: <https://repost.aws/knowledge-center/eks-cluster-back-up-restore>

# FAQs: Back up and restore an Amazon EKS cluster

I have some questions about how to back up and restore my Amazon Elastic Kubernetes Service (Amazon EKS) clusters.

**Q:** Does Amazon EKS provide native backup and restore capabilities?

Amazon EKS doesn't offer native backup and restore capabilities. However, you can integrate Amazon EKS with third-party tools that provide backup and restore functionalities for Kubernetes workloads.

**Q:** Can I use AWS Backup to back up my Amazon EKS cluster?

No. You can't use AWS Backup to back up an Amazon EKS cluster or the Kubernetes resources within the cluster. You can use AWS Backup to back up only AWS resources.

**Q:** What tool can I use to back up my Amazon EKS cluster?

Velero (formerly Heptio Ark) is a popular open source tool that you can use to back up and restore your Kubernetes resources. For more information, see [Back up and restore your Amazon EKS cluster resources using Velero](<https://aws.amazon.com/blogs/containers/backup-and-restore-your-amazon-eks-cluster-resources-using-velero/>).

**Q:** What data do I include in my backup strategy?

Your backup strategy must include the following:

  * Kubernetes resources, such as manifests and configurations
  * Application data that are stored within your cluster, such as databases and logs
  * Persistent volumes and associated data



**Q:** Does Velero back up the configurations that I installed with Helm?

Yes. Velero backs up the configurations that you installed with Helm. For more information about Helm, see the [Helm](<https://helm.sh/>) website. 

**Q:** During the restoration process, does Velero delete existing objects that aren't part of the restore?

No. Velero deletes only existing objects that are part of the restoration process.

**Q:** Is Velero supported by AWS?

Velero is a third-party tool and isn't supported by AWS. Issues that are related to Velero are outside the scope of AWS Support.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
