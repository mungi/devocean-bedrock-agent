Original URL: <https://repost.aws/knowledge-center/eks-cidr-ip-address-loadbalancer>

# How do I restrict CIDR IP addresses for a LoadBalancer type service in Amazon EKS?

I want to restrict CIDR IP addresses for a LoadBalancer type service in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

If you create a **LoadBalancer** type service, then requests from the source **0.0.0.0/0** are allowed by default. If your load balancer is in a public subnet, then requests are routed to worker nodes from anywhere on the internet.

To restrict the source instead of **0.0.0.0/0** , use **loadBalancerSourceRanges**.

## Resolution

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

### Set up your environment

To set up your environment, complete the following steps:

  1. [Create an Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html>).
  2. [Create](<https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html>), and then [launch](<https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html>) worker nodes.
  3. [Set up kubectl](<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>).
  4. [Set up the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html>).
  5. [Set up the AWS Load Balancer Controller](<https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html>).  
**Note:** For the **LoadBalancer** type service, the AWS Load Balancer Controller supports Network Load Balancer (NLB) IP mode version 2.0.0 or later and NLB instance mode 2.2.0 or later.



**Important:** To allocate a new Network Load Balancer for **LoadBalancer** type services, it's a best practice to use the AWS Load Balancer Controller instead of the Kubernetes Service load balancer controller. For the latest version of the AWS Balancer Controller, see [aws-load-balancer-controller](<https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases>) on the GitHub website.

### Restrict CIDR IP addresses

Choose one of the following methods to specify the **loadBalancerSourceRanges**.

**Use an annotation**

Use an annotation in your service manifest file (svc.yaml).

Example annotation:
    
    
    service.beta.kubernetes.io/load-balancer-source-ranges: 143.231.0.0/16

For more information, see [Access control](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/#lb-source-ranges>) on the Kubernetes website.

**Add the loadBalancerSourceRanges field**

  1. Add the **.spec.loadBalancerSourceRanges** field in your svc.yaml file:
    
        apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: nginx
      name: nginx
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: "external"
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
        service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    spec:
      ports:
      - port: 80
        protocol: TCP
        targetPort: 80
      selector:
        app: nginx
      type: LoadBalancer
      loadBalancerSourceRanges:
      - "143.231.0.0/16"

  2. Run the following command to apply your svc.yaml file:
    
        $ kubectl apply -f svc.yaml

Run the following command to check the AWS Load Balancer Controller pod logs:
    
        $ kubectl logs -f <aws load balancer controller pod> -n <namespace>

  3. The AWS Load Balancer Controller adds the configured load balancer source ranges in the security group's inbound rules. Run the following command to confirm that the inbound rules on the security group are modified:
    
        $ aws ec2 describe-security-groups --group-ids sg-XXXXXXXXXXXXXXXXX
    ...
        "CidrIp": "143.231.0.0/16"
    ...

  4. If you use a Network Load Balancer in IP mode, then the **.spec.loadBalancerSourceRanges** field is ignored by default. In this case, use the following annotation to turn on [client IP preservation](<https://docs.aws.amazon.com/elasticloadbalancing/latest/network/load-balancer-target-groups.html#client-ip-preservation>):
    
        service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: preserve_client_ip.enabled=true

For a service with a Network Load Balancer type, you might want to increase the maximum security group limit. For each node port and subnet CIDR range, the controller creates rules on the worker node's security group. For more information, see [Ingress traffic](<https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/how-it-works/#ingress-traffic>) on the Kubernetes website.

**Note:** For a service with a Network Load Balancer type, you might want to [increase the maximum security group quota](<https://repost.aws/knowledge-center/increase-security-group-rule-limit>). For each node port and subnet CIDR range, the controller creates rules on the worker node's security group. For example, you have worker nodes across three Availability Zones. You add a **loadBalancerSourceRange**. Three health check rules (one per subnet) and one **loadBalancerSourceRange** rule are created in the worker node security group. Security groups have a default limit of 60 rules. You can increase this quota, but the total number of security groups per network interface can't exceed 1,000.




## Related information

[Allowing users to access your cluster](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-auth.html>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
