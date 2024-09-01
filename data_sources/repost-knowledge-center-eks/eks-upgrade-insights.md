Original URL: <https://repost.aws/knowledge-center/eks-upgrade-insights>

# FAQs: Amazon EKS upgrade insights

I have a few questions about Amazon Elastic Kubernetes Service (Amazon EKS) upgrade insights.

**Q:** What checks do Amazon EKS upgrade insights provide?

Upgrade insights provide a concise overview of the following:

  * Checks that Amazon EKS performed against the cluster
  * Status of the insight checks, such as **Passing** , **Warning** , **Error** , and **Unknown**



The summary that upgrade insights provide helps you identify resources that need remedial action before you start to upgrade the cluster.

**Q:** How do Amazon EKS upgrade insights collect data on deprecated APIs?

Upgrade insights query Kubernetes control plane audit logs to retrieve data on deprecated APIs.

**Q:** What do I do if an API is marked as **Error** in my upgrade insights?

An insight with an **Error** status indicates that the affected Kubernetes version is one release later than the current cluster version. To resolve this error, update your resources that use deprecated APIs so that the resources use the latest versions.

**Q:** Why am I still seeing the "Error" status in my upgrade insights even after I updated my API version?

Amazon EKS uses a 30-day rolling window when it reads the Kubernetes audit logs. As a result, Amazon EKS continues to report all deprecated API usage within the last 30 days even after you update the API versions. A check's status remains as **Error** until the last audit log entry for the check passes the 30-day window.

**Q:** How frequently does Amazon EKS scan the clusters for upgrade insights?

Amazon EKS scans the cluster's audit logs once a day for resources that were deprecated and provides the insights on the Amazon EKS console.

**Q:** How do I view the list of upgrade insight checks and identified issues in Amazon EKS?

To view the list of upgrade insight checks and identified issues in Amazon EKS, use one of the following options:

  * Amazon EKS [ListInsights](<https://docs.aws.amazon.com/eks/latest/APIReference/API_ListInsights.html>) API operation
  * [Amazon EKS console](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-insights.html#cluster-insights-console>) for a more comprehensive view



* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
