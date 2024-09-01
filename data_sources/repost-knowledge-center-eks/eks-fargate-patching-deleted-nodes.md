Original URL: <https://repost.aws/knowledge-center/eks-fargate-patching-deleted-nodes>

# How do I check if AWS Fargate OS patching deleted my pods or nodes?

I want to check if AWS Fargate operating system (OS) patching deleted my Amazon Elastic Kubernetes Service (Amazon EKS) pods or nodes.

## Short description

To keep nodes secure, Amazon EKS periodically patches the OS for Fargate nodes. During the patching process, Amazon EKS recycles the nodes to install OS patches. In [Fargate OS patching](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-patching.html>), Amazon EKS uses the eviction API to safely drain the pod and records the API in Amazon EKS audit logs. If Fargate OS patching occurred, then confirm that logs for the eviction API appear in the audit logs. For more information, see the [Eviction API](<https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#eviction-api>) on the Kubernetes website.

## Resolution

To check that the eviction API appears in the audit logs, use the following example query:
    
    
    filter @logStream like /^kube-apiserver-audit/ | fields @timestamp, user.username, user.extra.canonicalArn.0, @message
     | sort @timestamp desc
     | filter verb == "create" and objectRef.subresource == 'eviction'
     | filter requestURI like "/api/v1/namespaces/NAMESPACE/pods/pod-name/"

**Note:** Replace **NAMESPACE** and **pod-name** with your values. To narrow down your search window, modify the time window in Amazon CloudWatch.  
Example audit log output:
    
    
    {
            "@logStream": "kube-apiserver-audit",
            "@timestamp": "xxx",
            "@message": {
                "kind": "Event",
                "apiVersion": "audit.k8s.io/v1",
                "level": "RequestResponse",
    ・・・
                "stage": "ResponseComplete",
                "requestURI": "/api/v1/namespaces/<Namespace>/pods/<Pod_Name>/eviction.."
                "verb": "create",
                "user": {
                    "username": "<username>",
    ・・・
                },
                "userAgent": "<agent>",
                "objectRef": {
                    "resource": "pods",
                    "namespace": "xxx",
                    "name": "xxx",
                    "apiVersion": "v1",
                    "subresource": "eviction"
                },
                "responseStatus": {
                    "metadata": {},
                    "status": "Success",
                    "code": 201
                },
                "requestObject": {
                    "kind": "Eviction",
                    "apiVersion": "policy/v1beta1",
                    "metadata": {
                        "name": "xxx",
                        "namespace": "xxx",
                        "creationTimestamp": null
                    }
                },

**Note:** To limit the number of pods that are down at the same time when pods are recycled, set pod disruption budgets. For more information, see [Specifying a disruption budget for your application](<https://kubernetes.io/docs/tasks/run-application/configure-pdb/>) on the Kubernetes website.

## Related information

[API-initiated eviction](<https://kubernetes.io/docs/concepts/scheduling-eviction/api-eviction/>) on the Kubernetes website

* * *

Topics

[Serverless](<https://repost.aws/topics/TA4h-jxxJrRJStoIIHfQySkA/serverless>)[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[AWS Fargate](<https://repost.aws/tags/TAdywHX42FRtu3_LYJXB0FJw/aws-fargate>)[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
