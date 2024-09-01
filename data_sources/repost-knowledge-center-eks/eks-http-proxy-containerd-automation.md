Original URL: <https://repost.aws/knowledge-center/eks-http-proxy-containerd-automation>

# How can I automate the configuration of HTTP proxy for Amazon EKS containerd nodes?

I want to automate the HTTP proxy configuration for Amazon Elastic Kubernetes Service (Amazon EKS) nodes with containerd runtime.

## Short description

For [managed node groups](<https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html>) that you created in Amazon EKS versions 1.23 or earlier, the default container runtime is Docker. If this is your use case, then follow all steps in the resolution to specify a **containerd** runtime. For managed node groups that are created in Amazon EKS version 1.24 or later, the default container runtime in **containerd**.

To use **containerd** in your managed node group instead of **dockerd** , you must specify a **containerd** runtime in **userdata**.

After you switch your managed node group to a containerd runtime, create a custom launch template with your Amazon Machine Image (AMI) ID. Then, configure the settings for your HTTP proxy and the environment values of your cluster.

**Note:** For nodes with Docker runtime, see [How can I automate the configuration of HTTP proxy for Amazon EKS worker nodes with Docker?](<https://repost.aws/knowledge-center/eks-http-proxy-configuration-automation>)

## Resolution

### Create a custom launch template

To specify **containerd** as the runtime and create a custom launch template, complete the following steps:

  1. Specify **containerd** as the runtime in your managed node group. In **userdata** , use the **\--container-runtime=containerd** option for **bootstrap.sh**.

  2. Create a [custom launch template](<https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html>) with the AMI ID. If you don't do this, then the managed nodes group automatically merges **userdata**.

  3. Set the proxy configuration to **containerd** , **sandbox-image** , and **kubelet**.  
**Note:** **Sandbox-image** is the service unit that pulls the sandbox image for **containerd**. To set this configuration, see the [sandbox-image.service](<https://github.com/awslabs/amazon-eks-ami/blob/master/files/sandbox-image.service>) and [pull-sandbox-image.sh](<https://github.com/awslabs/amazon-eks-ami/blob/master/files/pull-sandbox-image.sh>) scripts on the GitHub website.

  4. Describe your **userdata** with the following fields:
    
        MIME-Version: 1.0
    Content-Type: multipart/mixed; boundary="==BOUNDARY=="
    
    --==BOUNDARY==
    Content-Type: text/cloud-boothook; charset="us-ascii"
    
    #Set the proxy hostname and port
    PROXY=XXXXXXX:3128
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    MAC=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v -s http://169.254.169.254/latest/meta-data/mac/)
    VPC_CIDR=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/vpc-ipv4-cidr-blocks | xargs | tr ' ' ',')
    
    #Create the containerd and sandbox-image systemd directory
    mkdir -p /etc/systemd/system/containerd.service.d
    mkdir -p /etc/systemd/system/sandbox-image.service.d
    
    #[Option] Configure yum to use the proxy
    cloud-init-per instance yum_proxy_config cat << EOF >> /etc/yum.conf
    proxy=http://$PROXY
    EOF
    
    #Set the proxy for future processes, and use as an include file
    cloud-init-per instance proxy_config cat << EOF >> /etc/environment
    http_proxy=http://$PROXY
    https_proxy=http://$PROXY
    HTTP_PROXY=http://$PROXY
    HTTPS_PROXY=http://$PROXY
    no_proxy=$VPC_CIDR,localhost,127.0.0.1,169.254.169.254,.internal,.eks.amazonaws.com
    NO_PROXY=$VPC_CIDR,localhost,127.0.0.1,169.254.169.254,.internal,.eks.amazonaws.com
    EOF
    
    #Configure Containerd with the proxy
    cloud-init-per instance containerd_proxy_config tee <<EOF /etc/systemd/system/containerd.service.d/http-proxy.conf >/dev/null
    [Service]    
    EnvironmentFile=/etc/environment
    EOF
    
    #Configure sandbox-image with the proxy
    cloud-init-per instance sandbox-image_proxy_config tee <<EOF /etc/systemd/system/sandbox-image.service.d/http-proxy.conf >/dev/null
    [Service]    
    EnvironmentFile=/etc/environment
    EOF
    
    #Configure the kubelet with the proxy
    cloud-init-per instance kubelet_proxy_config tee <<EOF /etc/systemd/system/kubelet.service.d/proxy.conf >/dev/null
    [Service]
    EnvironmentFile=/etc/environment
    EOF
    
    cloud-init-per instance reload_daemon systemctl daemon-reload 
    
    --==BOUNDARY==
    Content-Type:text/x-shellscript; charset="us-ascii"
    
    #!/bin/bash
    set -o xtrace
    
    #Set the proxy variables before running the bootstrap.sh script
    set -a
    source /etc/environment
    
    #Run the bootstrap.sh script
    B64_CLUSTER_CA=YOUR_CLUSTER_CA
    API_SERVER_URL=API_SERVER_ENDPOINT
    
    /etc/eks/bootstrap.sh EKS_CLUSTER_NAME --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL --container-runtime containerd
    
    --==BOUNDARY==--

**Note:** Replace **XXXXXXX:3128** , **YOUR_CLUSTER_CA** , **API_SERVER_ENDPOINT** , and **EKS_CLUSTER_NAME** with your proxy, cluster certificate authority (CA), server endpoint, and cluster name. After you create the virtual private cloud (VPC) endpoints, add AWS service endpoints to **NO_PROXY** and **no_proxy**.




### Configure the proxy setting for aws-node and kube-proxy

**Note:** If you rout traffic from the cluster to the internet through an HTTP proxy and your EKS endpoint is public, then you must complete these steps. If you have a different configuration, then these steps are optional. 

Create a ConfigMap to configure the environment values. Then, apply the ConfigMap in your cluster. Use the following script as an example for your ConfigMap:
    
    
    apiVersion: v1
    kind: ConfigMap
    
    metadata:
    
       name: proxy-environment-variables
    
       namespace: kube-system
    
    data:
    
       HTTP_PROXY: http://XXXXXXX:3128
    
       HTTPS_PROXY: http://XXXXXXX:3128
    
       NO_PROXY: KUBERNETES_SERVICE_CIDR_RANGE,localhost,127.0.0.1,VPC_CIDR_RANGE,169.254.169.254,.internal

**Note:** Replace **KUBERNETES_SERVICE_CIDR_RANGE** and **VPC_CIDR_RANGE** with the values for your CIDR ranges. After you create the VPC endpoints, add AWS service endpoints to **NO_PROXY** and **no_proxy**.

Then, set your HTTP proxy configuration to **aws-node** and **kube-proxy** :
    
    
    $ kubectl patch -n kube-system -p '{ "spec": {"template":{ "spec": { "containers": [ { "name": "aws-node", "envFrom": [ { "configMapRef": {"name": "proxy-environment-variables"} } ] } ] } } } }' daemonset aws-node
    $ kubectl patch -n kube-system -p '{ "spec": {"template":{ "spec": { "containers": [ { "name": "kube-proxy", "envFrom": [ { "configMapRef": {"name": "proxy-environment-variables"} } ] } ] } } } }' daemonset kube-proxy 

### Create a managed node group

[Create a new managed node group](<https://docs.aws.amazon.com/eks/latest/userguide/create-managed-node-group.html>) that uses the custom launch template that you created.

### Test your proxy

To check the status of your nodes, run the following commands:
    
    
    $ kubectl get nodes
                
    $ kubectl run test-pod --image=amazonlinux:2 --restart=Never -- sleep 300
            
    $ kubectl get pods -A

You receive an output that's similar to the following example:
    
    
    $ kubectl get nodes -o wide
    NAME                                                 STATUS   ROLES    AGE     VERSION                INTERNAL-IP       EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                 CONTAINER-RUNTIME
    
    ip-192-168-100-114.ap-northeast-1.compute.internal   Ready    <none>   2m27s   v1.23.13-eks-fb459a0   192.168.100.114   <none>        Amazon Linux 2   5.4.219-126.411.amzn2.x86_64   containerd://1.6.6
    
    
    
    $ kubectl run test-pod --image=amazonlinux:2 --restart=Never -- sleep 300
    
    pod/test-pod created
    
    
    
    $ kubectl get pods -A
    
    NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
    
    default       test-pod                   1/1     Running   0          14s
    
    kube-system   aws-node-cpjcl             1/1     Running   0          3m34s
    
    kube-system   coredns-69cfddc4b4-c7rpd   1/1     Running   0          26m
    
    kube-system   coredns-69cfddc4b4-z5jxq   1/1     Running   0          26m
    
    kube-system   kube-proxy-g2f4g           1/1     Running   0          3m34s

Check your proxy log for additional information on your nodes' connectivity:
    
    
    192.168.100.114 TCP_TUNNEL/200 6230 CONNECT registry-1.docker.io:443 - HIER_DIRECT/XX.XX.XX.XX -
    192.168.100.114 TCP_TUNNEL/200 10359 CONNECT auth.docker.io:443 - HIER_DIRECT/XX.XX.XX.XX -
    192.168.100.114 TCP_TUNNEL/200 6633 CONNECT registry-1.docker.io:443 - HIER_DIRECT/XX.XX.XX.XX -
    192.168.100.114 TCP_TUNNEL/200 10353 CONNECT auth.docker.io:443 - HIER_DIRECT/XX.XX.XX.XX -
    192.168.100.114 TCP_TUNNEL/200 8767 CONNECT registry-1.docker.io:443 - HIER_DIRECT/XX.XX.XX.XX -

## Related information

[How do I provide access to other IAM users and roles after cluster creation in Amazon EKS?](<https://repost.aws/knowledge-center/amazon-eks-cluster-access?nc1=h_ls>)

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
