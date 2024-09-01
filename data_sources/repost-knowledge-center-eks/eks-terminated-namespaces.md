Original URL: <https://repost.aws/knowledge-center/eks-terminated-namespaces>

# How do I troubleshoot namespaces in a terminated state in my Amazon EKS cluster?

I tried to delete a namespace in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster. However, the namespace is stuck in the "Terminating" status.

## Short description

To delete a namespace, Kubernetes must first delete all the resources in the namespace. Then, it must check registered API services for the status. A namespace gets stuck in **Terminating** status for the following reasons:

  * The namespace contains resources that Kubernetes can't delete.
  * An API service has a **False** status.



## Resolution

1\. Save a JSON file like in the following example:
    
    
    kubectl get namespace TERMINATING_NAMESPACE -o json > tempfile.json

**Note:** Replace **TERMINATING_NAMESPACE** with the name of your stuck namespace.

2\. Remove the finalizers array block from the **spec** section of the JSON file:
    
    
    "spec": {
            "finalizers": [
                "kubernetes"
            ]
        }

After you remove the finalizers array block, the **spec** section of the JSON file looks like this:
    
    
    "spec" : {
        }

3\. To apply the changes, run the following command:
    
    
    kubectl replace --raw "/api/v1/namespaces/TERMINATING_NAMESPACE/finalize" -f ./tempfile.json

**Note:** Replace **TERMINATING_NAMESPACE** with the name of your stuck namespace.

4\. Verify that the terminating namespace is removed:
    
    
    kubectl get namespaces

Repeat these steps for any remaining namespaces that are stuck in the **Terminating** status.

## Related information

[What is Amazon EKS?](<https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html>)

[Namespaces](<https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/>) (on the Kubernetes site)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
