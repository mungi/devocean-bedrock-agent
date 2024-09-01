Original URL: <https://repost.aws/knowledge-center/eks-api-server-endpoint-failed>

# How do I troubleshoot connectivity issues with the API server endpoint of my Amazon EKS cluster?

I can't run kubectl commands. Also, I changed the endpoint access setting from public to private on my Amazon Elastic Kubernetes Service (Amazon EKS) cluster. Now, my cluster is stuck in the Failed state.

## Short description

Based on your issue, complete the steps in one of the following sections.

**Note:** To set up access to the Kubernetes API server endpoint, see [Modifying cluster endpoint access](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#modify-endpoint-access>).

## Resolution

### You can't run kubectl commands on the new or existing cluster

**Confirm that your kubeconfig file connects to your cluster**

Complete the following steps:

  1. Confirm that you use the correct kubeconfig file to connect with your cluster. For more information, see [Organizing cluster access using kubeconfig files](<https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/>) on the Kubernetes website.
  2. Check each cluster for multiple contexts in your kubeconfig files.  
Example output:
    
        $ kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'
    Cluster name    Server
    new200.us-east-2.eksctl.io       https://D8DC9092A7985668FF67C3D1C789A9F5.gr7.us-east-2.eks.amazonaws.com

If the kubeconfig file in use doesn't have the correct cluster details, then run the following command to create a new entry for the cluster:
    
        aws eks update-kubeconfig --name CLUSTER NAME --region REGION

**Note:** Replace **CLUSTER NAME** with your cluster's name and **REGION** with your AWS Region.
  3. Use telnet on port 443 to check the API server endpoint connectivity from your device.  
Example output:
    
        $ echo exit | telnet D8DC9092A7985668FF67C3D1C789A9F5.gr7.us-east-2.eks.amazonaws.com 443
    Trying 18.224.160.210...
    Connected to D8DC9092A7985668FF67C3D1C789A9F5.gr7.us-east-2.eks.amazonaws.com.
    Escape character is '^]'.
    Connection closed by foreign host.

If the telnet command doesn't work, then complete the following steps to troubleshoot.



**Check the DNS resolver**

If the API server doesn't resolve, then there's an issue with the DNS resolver.

Run the following command from the same device where the **kubectl** commands failed:
    
    
    nslookup APISERVER ENDPOINT

**Note:** Replace **APISERVER ENDPOINT** with your cluster's API server endpoint.

**Check if you restricted public access to the API server endpoint**

If you specified CIDR blocks to limit access to the public API server endpoint, then it's best practice to also activate private endpoint access.

Check the API server endpoint access behavior. See [Modifying cluster endpoint access](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html#modify-endpoint-access>).

### You can't run kubectl commands on the cluster after you change the endpoint access from public to private

To resolve this issue, complete the following steps:

  1. Confirm that you use a bastion host or connected networks, such as peered virtual private clouds (VPCs), AWS Direct Connect, or VPNs, to access the Amazon EKS API endpoint.  
**Note:** In private access mode, you can access the Amazon EKS API endpoint only from within the cluster's VPC or connected networks.
  2. Check if security groups or network access control lists block requests to the Kubernetes API server.  
If you access your cluster across a [peered VPC](<https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-security-groups.html>), then confirm that the control plane security groups allow the correct access. They must allow access from the [peered VPC](<https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-security-groups.html>) to the Amazon EKS control plane security groups on port 443.



### Your cluster is stuck in the Failed state and you can't change the endpoint access setting from public to private

Your cluster might be in the **Failed** state because of a permissions issue with AWS Identity and Access Management (IAM).

To resolve this issue, complete the following steps:

  1. Confirm that the IAM role for the user is authorized to perform the [AssociateVPCWithHostedZone](<https://docs.aws.amazon.com/Route53/latest/APIReference/API_AssociateVPCWithHostedZone.html>) action.  
**Note:** If the action isn't blocked, then check if the user's account has [AWS Organizations policies](<https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scp.html#scp-effects-on-permissions>) that block the API calls and cause the cluster to fail.
  2. Confirm that the IAM user's permission isn't implicitly or explicitly blocked at any level above the account.  
**Note:** IAM user permission is implicitly blocked if it's not included in the **Allow** policy statement. It's explicitly blocked if it's included in the **Deny** policy statement. Permission is blocked even if the account administrator attaches the **AdministratorAccess** IAM policy with ***/*** permissions to the user. Permissions from AWS Organizations policies override the permissions for IAM entities.



* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
