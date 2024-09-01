Original URL: <https://repost.aws/knowledge-center/eks-cluster-connection>

# Why can't I connect to my Amazon EKS cluster?

I created an Amazon Elastic Kubernetes Service (Amazon EKS) cluster, but I can't connect to my cluster.

## Short description

You might not be able to connect to your EKS cluster because of one of the following reasons:

  * You didn't create the kubeconfig file for your cluster.
  * You are unable to connect to the Amazon EKS API server endpoint.



## Resolution

### You didn't create the kubeconfig file

After you create your Amazon EKS cluster, you must configure your **kubeconfig** file using the AWS Command Line Interface (AWS CLI). This configuration allows you to connect to your cluster using the **kubectl** command line. The following resolution shows you how to create a kubeconfig file for your cluster with the AWS CLI **update-kubeconfig** command. To manually update your kubeconfig file without using the AWS CLI, see [Creating or updating a kubeconfig file for an Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html>).

**Note:** If you receive errors when running AWS CLI commands, [make sure that you’re using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html#general-latest>).

1\. Verify that the AWS CLI version 1.16.308 or later is installed on your system:
    
    
    $ aws --version

**Important:** You must have Python version 2.7.9 or later installed on your system. Otherwise, you receive an error.

**Tip:** Use package managers such as **yum** , **apt-get** , or **homebrew** for macOS to install the AWS CLI.

2\. Check the current identity to verify that you're using the correct credentials that have permissions for the Amazon EKS cluster:
    
    
    aws sts get-caller-identity

**Note:** The AWS Identity and Access Management (IAM) entity user or role that creates an Amazon cluster is automatically granted permissions when the cluster is created. These permissions are granted in the cluster's RBAC configuration in the control plane. IAM users or roles can also be granted access to an Amazon EKS cluster in [aws-auth ConfigMap](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>). By default, the [AWS IAM Authenticator for Kubernetes](<https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html>) uses the configured AWS CLI or AWS SDK identity. For more information, see [Turning on IAM user and role access to your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>).

3\. Create or update the **kubeconfig** file for your cluster:
    
    
    aws eks --region example_region update-kubeconfig --name cluster_name

**Note:** Replace **example_region** with the name of your AWS Region. Replace **cluster_name** with your EKS cluster name.

By default, the configuration file for Linux is created at the **kubeconfig** path (**$HOME/.kube/config**) in your home directory. The file might also be merged with an existing **kubeconfig** at that location. For Windows, the file is at **%USERPROFILE%\\.kube\config**.

You can also specify another path by setting the [KUBECONFIG](<https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#the-kubeconfig-environment-variable>) (from the Kubernetes website) environment variable, or with the following **\--kubeconfig** option:
    
    
    $ kubectl get pods --kubeconfig ./.kube/config

**Note:** For authentication when running **kubectl** commands, you can specify an IAM role Amazon Resource Name (ARN) with the **\--role-arn** option. Otherwise, the IAM entity in your default AWS CLI or AWS SDK credential chain is used. For more information, see [update-kubeconfig](<https://awscli.amazonaws.com/v2/documentation/api/latest/reference/eks/update-kubeconfig.html>). Or, complete Step 6 in the **Create kubeconfig file manually** section of [Creating or updating a kubeconfig file for an Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html>).

4\. Test your configuration:
    
    
    $ kubectl get svc

Example output:
    
    
    NAME             TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    svc/kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   1m

**Note:** If you receive other authorization or resource type errors, see [Unauthorized or access denied (kubectl)](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized>).

### You can't connect to the Amazon EKS API server endpoint

1\. Verify that you're connecting to the correct Amazon EKS API server URL. To do so, turn on kubectl verbosity, and then run the following command:
    
    
    $ kubectl get svc --v=9

The output looks similar to the following:
    
    
    I0110 16:43:36.920095   48173 loader.go:373] Config loaded from file:  /Users/abs/.kube/config
    I0110 16:43:36.936844   48173 round_trippers.go:466] curl -v -XGET  -H "Accept: application/json;as=Table;v=v1;g=meta.k8s.io,application/json;as=Table;v=v1beta1;g=meta.k8s.io,application/json" -H "User-Agent: kubectl/v1.26.0 (darwin/arm64) kubernetes/b46a3f8" 'https://S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com//api/v1/namespaces/default/services?limit=500'
    I0110 16:43:37.362185   48173 round_trippers.go:495] HTTP Trace: DNS Lookup for S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com/ resolved to [{18.119.155.77 } {3.136.153.3 }]
    I0110 16:43:37.402538   48173 round_trippers.go:510] HTTP Trace: Dial to tcp:18.119.155.77:443 succeed
    I0110 16:43:37.500276   48173 round_trippers.go:553] GET https://S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com//api/v1/namespaces/default/services?limit=500 200 OK in 563 milliseconds
    I0110 16:43:37.500302   48173 round_trippers.go:570] HTTP Statistics: DNSLookup 1 ms Dial 40 ms TLSHandshake 44 ms ServerProcessing 52 ms Duration 563 ms
    I0110 16:43:37.500308   48173 round_trippers.go:577] Response Headers:
    I0110 16:43:37.500316   48173 round_trippers.go:580] Audit-Id: 37c17136-7fa7-40e9-8fe6-b24426e81564
    I0110 16:43:37.500323   48173 round_trippers.go:580] Cache-Control: no-cache, private
    I0110 16:43:37.500329   48173 round_trippers.go:580] Content-Type: application/json
    I0110 16:43:37.500334   48173 round_trippers.go:580] X-Kubernetes-Pf-Flowschema-Uid: 508eb99e-d99b-44db-8ade-838c99fe8e9f
    I0110 16:43:37.500340   48173 round_trippers.go:580] X-Kubernetes-Pf-Prioritylevel-Uid: d324d3db-05ce-441b-a0ff-c31cbe8f696c
    I0110 16:43:37.500345   48173 round_trippers.go:580] Date: Tue, 10 Jan 2023 21:43:37 GMT

2\. Verify that the Amazon EKS API server is accessible publicly by running the following command:
    
    
    $ aws eks describe-cluster --name cluster_name --region example_region --query cluster.resourcesVpcConfig

The output looks similar to the following:
    
    
    {
        "subnetIds": [
            "subnet-abc1",
            "subnet-abc2",
            "subnet-abc3",
            "subnet-abc4",
            "subnet-abc5",
            "subnet-abc6"
        ],
        "securityGroupIds": [
           "sg-abc7"
        ],
        "clusterSecurityGroupId": "sg-abc7",
        "vpcId": "vpc-abc9",
        "endpointPublicAccess": true,
        "endpointPrivateAccess": false,
        "publicAccessCidrs": [
            "0.0.0.0/0"
        ]
    }

3\. In the preceding output, if **endpointPublicAccess** is **true** , then be sure that you allowlist all the source IP addresses in the **publicAccessCidrs** list. To do so, do the following:

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/home#/clusters>).
  2. Choose the cluster that you want to update.
  3. Choose the **Networking** tab, and then choose **Manage Networking**.
  4. Select **Public.**
  5. Under **Advanced settings** , for **CIDR block** , enter all the public CIDR range that needs to be allowlisted.
  6. Choose **Save changes**.



In the preceding output, if **endPointPrivateAccess** is **true** , then be sure that the kubectl request is coming from within the cluster's network. If your kubectl request is from outside of your Amazon Virtual Private Cloud (Amazon VPC), then you get the following timeout error:
    
    
    $ kubectl get svc --v=9
    I0110 17:15:58.889798   50514 loader.go:373] Config loaded from file:  /Users/example-user/.kube/config
    I0110 17:15:58.896715   50514 round_trippers.go:466] curl -v -XGET  -H "Accept: application/json;as=Table;v=v1;g=meta.k8s.io,application/json;as=Table;v=v1beta1;g=meta.k8s.io,application/json" -H "User-Agent: kubectl/v1.26.0 (darwin/arm64) kubernetes/b46a3f8" 'https://S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com/api/v1/namespaces/default/services?limit=500'
    I0110 17:15:59.374499   50514 round_trippers.go:495] HTTP Trace: DNS Lookup for S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com resolved to [{192.168.126.17 } {192.168.144.26 }]
    I0110 17:16:14.285027   50514 round_trippers.go:508] HTTP Trace: Dial to tcp:192.168.126.17:443 failed: dial tcp 192.168.126.17:443: i/o timeout
    I0110 17:16:29.191768   50514 round_trippers.go:508] HTTP Trace: Dial to tcp:192.168.144.26:443 failed: dial tcp 192.168.144.26:443: i/o timeout
    I0110 17:16:29.196959   50514 round_trippers.go:553] GET https://S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com/api/v1/namespaces/default/services?limit=500  in 30300 milliseconds
    I0110 17:16:29.197724   50514 round_trippers.go:570] HTTP Statistics: DNSLookup 183 ms Dial 14906 ms TLSHandshake 0 ms Duration 30300 ms
    I0110 17:16:29.197768   50514 round_trippers.go:577] Response Headers:
    I0110 17:16:29.199254   50514 helpers.go:264] Connection error: Get https://S123GBNS3HJUFN467UFGH6782JHCH2891.yl4.us-east-2.eks.amazonaws.com/api/v1/namespaces/default/services?limit=500: dial tcp 192.168.126.17:443: i/o timeout
    Unable to connect to the server: dial tcp 192.168.126.17:443: i/o timeout

Also, update the cluster security group to make sure that the source IP or CIDR range is allowlisted. This allows the kubectl client to connect to the Amazon EKS API server endpoint.

## Related information

[Amazon EKS troubleshooting](<https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html>)

[How do I resolve the error "You must be logged in to the server (Unauthorized)" when I connect to the Amazon EKS API server?](<https://repost.aws/knowledge-center/eks-api-server-unauthorized-error>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
