Original URL: <https://repost.aws/knowledge-center/eks-http-proxy-configuration-automation>

# How can I automate the configuration of HTTP proxy for Amazon EKS worker nodes with Docker?

I want to automate the configuration of HTTP proxy for Amazon Elastic Kubernetes Service (Amazon EKS) worker nodes with user data.

## Short description

To set up a proxy on worker nodes, you must configure the necessary components of your Amazon EKS cluster to communicate from the proxy. Components include, but are not limited to, the kubelet systemd service, kube-proxy, aws-node pods, and yum update. To automate the configuration of proxy for worker nodes with Docker runtime, do the following: 

**Note:** The following resolution applies only nodes where the underlying runtime is Docker, and doesn't apply to nodes with containerd runtime. For nodes with containerd runtime, see [How can I automate the configuration of HTTP proxy for EKS containerd nodes?](<https://repost.aws/knowledge-center/eks-http-proxy-containerd-automation>)

## Resolution

1\. Find your cluster's IP CIDR block:
    
    
    $ kubectl get service kubernetes -o jsonpath='{.spec.clusterIP}'; echo

The preceding command returns either **10.100.0.1** or **172.20.0.1**. This means that your cluster IP CIDR block is either **10.100.0.0/16** or **172.20.0.0/16**.

2\. Create a ConfigMap file named **proxy-env-vars-config.yaml** based on the output from the command in step 1.

If the output has an IP from the range **172.20.x.x** , then structure your ConfigMap file as follows:
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
     name: proxy-environment-variables
     namespace: kube-system
    data:
     HTTP_PROXY: http://customer.proxy.host:proxy_port
     HTTPS_PROXY: http://customer.proxy.host:proxy_port
     NO_PROXY: 172.20.0.0/16,localhost,127.0.0.1,VPC_CIDR_RANGE,169.254.169.254,.internal,s3.amazonaws.com,.s3.us-east-1.amazonaws.com,api.ecr.us-east-1.amazonaws.com,dkr.ecr.us-east-1.amazonaws.com,ec2.us-east-1.amazonaws.com

**Note:** Replace **VPC_CIDR_RANGE** with the IPv4 CIDR block of your cluster's VPC.

If the output has an IP from the range **10.100.x.x** , then structure your ConfigMap file as follows:
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
     name: proxy-environment-variables
     namespace: kube-system
    data:
     HTTP_PROXY: http://customer.proxy.host:proxy_port
     HTTPS_PROXY: http://customer.proxy.host:proxy_port
     NO_PROXY: 10.100.0.0/16,localhost,127.0.0.1,VPC_CIDR_RANGE,169.254.169.254,.internal,s3.amazonaws.com,.s3.us-east-1.amazonaws.com,api.ecr.us-east-1.amazonaws.com,dkr.ecr.us-east-1.amazonaws.com,ec2.us-east-1.amazonaws.com

**Note:** Replace **VPC_CIDR_RANGE** with the IPv4 CIDR block of your cluster's VPC.

Amazon EKS clusters with private API server endpoint access, private subnets, and no internet access require additional endpoints. If you're building a cluster with the preceding configuration, then you must create and add endpoints for the following services:

  * Amazon Elastic Container Registry (Amazon ECR)
  * Amazon Simple Storage Service (Amazon S3)
  * Amazon Elastic Compute Cloud (Amazon EC2)
  * Amazon Virtual Private Cloud (Amazon VPC)



For example, you can use the following endpoints: **api.ecr.us-east-1.amazonaws.com** , **dkr.ecr.us-east-1.amazonaws.com** , **s3.amazonaws.com** , **s3.us-east-1.amazonaws.com** , and **ec2.us-east-1.amazonaws.com**.

**Important:** You must add the public endpoint subdomain to the **NO_PROXY** variable. For example, add the **.s3.us-east-1.amazonaws.com** domain for Amazon S3 in the **us-east-1** AWS Region. If you activate [endpoint private access](<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html>) for your Amazon EKS cluster, then you must add the Amazon EKS endpoint to the **NO_PROXY** variable. For example, add the **.us-east-1.eks.amazonaws.com** domain for your Amazon EKS cluster in the **us-east-1** AWS Region.

3\. Verify that the **NO_PROXY** variable in **configmap/proxy-environment-variables** (used by the **kube-proxy** and **aws-node** pods) includes the Kubernetes cluster IP address space. For example, **10.100.0.0/16** is used in the preceding code example for the ConfigMap file where the IP range is from **10.100.x.x**.

4\. Apply the ConfigMap:
    
    
    $ kubectl apply -f /path/to/yaml/proxy-env-vars-config.yaml

5\. To configure the Docker daemon and **kubelet** , inject user data into your worker nodes. For example:
    
    
    Content-Type: multipart/mixed; boundary="==BOUNDARY=="
    MIME-Version:  1.0
    
    --==BOUNDARY==
    Content-Type: text/cloud-boothook; charset="us-ascii"
    
    #Set the proxy hostname and port
    PROXY="proxy.local:3128"
    MAC=$(curl -s http://169.254.169.254/latest/meta-data/mac/)
    VPC_CIDR=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-ipv4-cidr-blocks | xargs | tr ' ' ',')
    
    #Create the docker systemd directory
    mkdir -p /etc/systemd/system/docker.service.d
    
    #Configure yum to use the proxy
    cloud-init-per instance yum_proxy_config cat << EOF >> /etc/yum.conf
    proxy=http://$PROXY
    EOF
    
    #Set the proxy for future processes, and use as an include file
    cloud-init-per instance proxy_config cat << EOF >> /etc/environment
    http_proxy=http://$PROXY
    https_proxy=http://$PROXY
    HTTP_PROXY=http://$PROXY
    HTTPS_PROXY=http://$PROXY
    no_proxy=$VPC_CIDR,localhost,127.0.0.1,169.254.169.254,.internal,s3.amazonaws.com,.s3.us-east-1.amazonaws.com,api.ecr.us-east-1.amazonaws.com,dkr.ecr.us-east-1.amazonaws.com,ec2.us-east-1.amazonaws.com
    NO_PROXY=$VPC_CIDR,localhost,127.0.0.1,169.254.169.254,.internal,s3.amazonaws.com,.s3.us-east-1.amazonaws.com,api.ecr.us-east-1.amazonaws.com,dkr.ecr.us-east-1.amazonaws.com,ec2.us-east-1.amazonaws.com
    EOF
    
    #Configure docker with the proxy
    cloud-init-per instance docker_proxy_config tee <<EOF /etc/systemd/system/docker.service.d/proxy.conf >/dev/null
    [Service]
    EnvironmentFile=/etc/environment
    EOF
    
    #Configure the kubelet with the proxy
    cloud-init-per instance kubelet_proxy_config tee <<EOF /etc/systemd/system/kubelet.service.d/proxy.conf >/dev/null
    [Service]
    EnvironmentFile=/etc/environment
    EOF
    
    #Reload the daemon and restart docker to reflect proxy configuration at launch of instance
    cloud-init-per instance reload_daemon systemctl daemon-reload 
    cloud-init-per instance enable_docker systemctl enable --now --no-block docker
    
    --==BOUNDARY==
    Content-Type:text/x-shellscript; charset="us-ascii"
    
    #!/bin/bash
    set -o xtrace
    
    #Set the proxy variables before running the bootstrap.sh script
    set -a
    source /etc/environment
    
    /etc/eks/bootstrap.sh ${ClusterName} ${BootstrapArguments}
    
    # Use the cfn-signal only if the node is created through an AWS CloudFormation stack and needs to signal back to an AWS CloudFormation resource (CFN_RESOURCE_LOGICAL_NAME) that waits for a signal from this EC2 instance to progress through either:
    # - CreationPolicy https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-creationpolicy.html
    # - UpdatePolicy https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html
    # cfn-signal will signal back to AWS CloudFormation using https transport, so set the proxy for an HTTPS connection to AWS CloudFormation
    /opt/aws/bin/cfn-signal
        --exit-code $? \
        --stack  ${AWS::StackName} \
        --resource CFN_RESOURCE_LOGICAL_NAME  \
        --region ${AWS::Region} \
        --https-proxy $HTTPS_PROXY
    
    --==BOUNDARY==--

**Important:** You must update or create **yum** , **Docker** , and **kubelet** configuration files before starting the Docker daemon and **kubelet**.

For an example of user data that's injected into worker nodes using an AWS CloudFormation template, see [Launching self-managed Amazon Linux nodes](<https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html>).

6\. Update the **aws-node** and **kube-proxy** pods:
    
    
    $ kubectl patch -n kube-system -p '{ "spec": {"template": { "spec": { "containers": [ { "name": "aws-node", "envFrom": [ { "configMapRef": {"name": "proxy-environment-variables"} } ] } ] } } } }' daemonset aws-node
    $ kubectl patch -n kube-system -p '{ "spec": {"template":{ "spec": { "containers": [ { "name": "kube-proxy", "envFrom": [ { "configMapRef": {"name": "proxy-environment-variables"} } ] } ] } } } }' daemonset kube-proxy

If you change the ConfigMap, then apply the updates, and set the ConfigMap in the pods again. For example:
    
    
    $ kubectl set env daemonset/kube-proxy --namespace=kube-system --from=configmap/proxy-environment-variables --containers='*'
    $ kubectl set env daemonset/aws-node --namespace=kube-system --from=configmap/proxy-environment-variables --containers='*'

**Important:** You must update all YAML modifications to the Kubernetes objects **kube-proxy** or **aws-node** when these objects are upgraded. To update a ConfigMap to a default value, use the **eksctl** **utils update-kube-proxy** or **eksctl utils update-aws-node** commands.

**Tip:** If the proxy loses connectivity to the API server, then the proxy becomes a single point of failure and your cluster's behavior can be unpredictable. To prevent your proxy from becoming a single point of failure, run your proxy behind a service discovery namespace or load balancer.

7\. Confirm that the proxy variables are used in the **kube-proxy** and **aws-node** pods:
    
    
    $ kubectl describe pod kube-proxy-xxxx -n kube-system

The output is similar to the following:
    
    
    Environment:
     HTTPS_PROXY: <set to the key 'HTTPS_PROXY' of config map 'proxy-environment-variables'> Optional: false
     HTTP_PROXY: <set to the key 'HTTP_PROXY' of config map 'proxy-environment-variables'> Optional: false
     NO_PROXY: <set to the key 'NO_PROXY' of config map 'proxy-environment-variables'> Optional: false

If you're not using AWS PrivateLink, then verify access to API endpoints through a proxy server for Amazon EC2, Amazon ECR, and Amazon S3.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
