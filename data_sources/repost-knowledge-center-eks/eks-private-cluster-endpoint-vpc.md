Original URL: <https://repost.aws/knowledge-center/eks-private-cluster-endpoint-vpc>

# How do I connect to a private Amazon EKS cluster endpoint from outside the Amazon VPC?

I want to connect to a private Amazon Elastic Kubernetes Service (Amazon EKS) cluster endpoint from outside the Amazon Virtual Private Cloud (Amazon VPC). For example, I want to connect a peered VPC to AWS Direct Connect.

## Resolution

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

You can use a peered VPC to automatically resolve to the private Amazon EKS cluster endpoint.

Run the following command to check the connectivity between your local machine and the EKS endpoint:
    
    
    curl -iv EKS API SERVER ENDPOINT 

**Note:** Make sure that your cluster API server endpoint is an HTTPS URL.

If you activate only private endpoint access, then Amazon EKS automatically advertises the endpoints' private IP addresses through the API server's public DNS name. If you configure your client through **aws eks update-kubeconfig** or **eksctl** , then the client uses the public DNS name to resolve and connect to private endpoints. The client automatically performs these actions through the peered VPC. For an example of this type of client, see [Command line tool (kubectl)](<https://kubernetes.io/docs/reference/kubectl/>) on the Kubernetes website.

For more information, see [Accessing a private only API server](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#private-access>).

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
