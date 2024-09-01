Original URL: <https://repost.aws/knowledge-center/eks-troubleshoot-kubectl-commands>

# Why am I unable to run kubectl commands in Amazon EKS?

I can't successfully run kubectl commands, such as kubectl exec, kubectl logs, kubectl attach, or kubectl port-forward, in Amazon Elastic Kubernetes Service (Amazon EKS).

## Resolution

Typically, kubectl commands fail in your Amazon EKS cluster because the API server isn't communicating with the kubelet that runs on worker nodes. Common kubectl commands include **kubectl exec** , **kubectl logs** , **kubectl attach** , or **kubectl port-forward**.

To troubleshoot this issue, verify the following:

  * Pods are running in secondary Classless Inter-Domain Routing (CIDR) range.
  * Security groups that are used for the control plane and node use the best practices for inbound and outbound rules.
  * The **aws-auth** ConfigMap has the correct AWS Identity and Access Management (IAM) role with the Kubernetes user name that's associated with your node.
  * The requirement to submit a new certificate is fulfilled.



### Pods are running in secondary Classless Inter-Domain Routing (CIDR) range

Immediately after you create a cluster, Amazon EKS can't communicate with nodes launched in subnets from CIDR blocks added to a virtual private cloud (VPC). An updated range caused by adding CIDR blocks to an existing cluster can take as long as five hours to be recognized by Amazon EKS. For more information, see [Amazon EKS VPC and subnet requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html>).

If the pods are running in secondary CIDR range, then take the following actions:

  * Wait up to five hours for these commands to start working.
  * Be sure that you have at least five free IP addresses in each subnet to successfully complete the automation.



Use the following example policy to view the free IP addresses for all subnets in any VPC:
    
    
    [ec2-user@ip-172-31-51-214 ~]$ aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-078af71a874f2f068" | jq '.Subnets[] | .SubnetId + "=" + "\(.AvailableIpAddressCount)"'
    "subnet-0d89886ca3fb30074=8186"
    "subnet-0ee46aa228bdc9a74=8187"
    "subnet-0a0186a277b8b6a51=8186"
    "subnet-0d1fb1de0732b5766=8187"
    "subnet-077eff87a4e25316d=8187"
    "subnet-0f01c02b04708f638=8186"

### Security groups that are used for the control plane and node have the minimum required inbound and outbound rules

When running on worker nodes, an API server must have the minimum required inbound and outbound rules to make an API call to kublet. To verify that the control plane and node security groups have the minimum required inbound and outbound rules, see [Amazon EKS security group requirements and considerations](<https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#control-plane-worker-node-sgs>).

### The aws-auth ConfigMap has the correct IAM role with the Kubernetes user name associated with your node

You must apply the correct IAM role to the **aws-auth** ConfigMap. Make sure that the IAM role has the Kubernetes user name that's associated with your node. To apply the **aws-auth** ConfigMap to your cluster, see [Add IAM users or roles to your Amazon EKS cluster](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html#aws-auth-users>).

### The requirement to submit a new certificate is fulfilled

Amazon EKS clusters require the node's kubelet to submit and rotate the serving certificate for itself. A cert error occurs when a serving certificate isn't available.

1\. Run the following command to validate the kubelet server certificate:
    
    
    cd /var/lib/kubelet/pki/# use openssl command to validate kubelet server cert 
    sudo openssl x509 -text -noout -in kubelet-server-current.pem

The output looks similar to the following one:
    
    
    Certificate:
        Data:
            Version: 3 (0x2)
            Serial Number:
                1e:f1:84:62:a3:39:32:c7:30:04:b5:cf:b0:91:6e:c7:bd:5d:69:fb
        Signature Algorithm: sha256WithRSAEncryption
            Issuer: CN=kubernetes
            Validity
                Not Before: Oct 11 19:03:00 2021 GMT
                Not After : Oct 11 19:03:00 2022 GMT
            Subject: O=system:nodes, CN=system:node:ip-192-168-65-123.us-east-2.compute.internal
            Subject Public Key Info:
                Public Key Algorithm: id-ecPublicKey
                    Public-Key: (256 bit)
                    pub:
                        04:7f:44:c6:95:7e:0f:1e:f8:f8:bf:2e:f8:a9:40:
                        6a:4f:83:0a:e8:89:7b:87:cb:d6:b8:47:4e:8d:51:
                        00:f4:ac:9d:ef:10:e4:97:4a:1b:69:6f:2f:86:df:
                        e0:81:24:c6:62:d2:00:b8:c7:60:da:97:db:da:b7:
                        c3:08:20:6e:70
                    ASN1 OID: prime256v1
                    NIST CURVE: P-256
            X509v3 extensions:
                X509v3 Key Usage: critical
                    Digital Signature, Key Encipherment
                X509v3 Extended Key Usage:
                    TLS Web Server Authentication
                X509v3 Basic Constraints: critical
                    CA:FALSE
                X509v3 Subject Key Identifier:
                    A8:EA:CD:1A:5D:AB:DC:47:A0:93:31:59:ED:05:E8:7E:40:6D:ED:8C
                X509v3 Authority Key Identifier:
                    keyid:2A:F2:F7:E8:F6:1F:55:D1:74:7D:59:94:B1:45:23:FD:A1:8C:97:9B
    
                X509v3 Subject Alternative Name:
                    DNS:ec2-3-18-214-69.us-east-2.compute.amazonaws.com, DNS:ip-192-168-65-123.us-east-2.compute.internal, IP Address:192.168.65.123, IP Address:3.18.214.69

2\. Review the kubelet logs for cert errors. If you don't see an error, then the requirement to submit new certificates is fulfilled.

Example of a kubelet log cert error:
    
    
    kubelet[8070]: I1021 18:49:21.594143 8070 log.go:184] http: TLS handshake error from 192.168.130.116:38710: no serving certificate available for the kubelet

**Note:** For more detailed logs, turn on kubelet detailed logs with flag **\--v=4** and then restart the kubelet on worker node. The kubelet detailed log looks similar to the following one:
    
    
    #kubelet verbosity can be increased by updating this file ...max verbosisty level --v=4
    sudo vi /etc/systemd/system/kubelet.service.d/10-kubelet-args.conf
    # Normal kubelet verbosisty is 2 by default
    cat /etc/systemd/system/kubelet.service.d/10-kubelet-args.conf
    [Service]
    Environment='KUBELET_ARGS=--node-ip=192.168.65.123 --pod-infra-container-image=XXXXXXXXXX.dkr.ecr.us-east-2.amazonaws.com/eks/pause:3.1-eksbuild.1 --v=2
    #to restart the demon and kubelet
    sudo systemctl daemon-reload
    sudo systemctl restart kubelet
    #make sure kubelet in running state
    sudo systemctl status kubelet
    # to stream logs for kubelet
    journalctl -u kubelet -f

3\. If you see an error, verify the kubelet config file: **/etc/kubernetes/kubelet/kubelet-config.json** on the worker node, and then confirm that the **RotateKubeletServerCertificate** and **serverTLSBootstrap** flags are listed as true:
    
    
    "featureGates": {
    	"RotateKubeletServerCertificate": true
    },
    "serverTLSBootstrap": true,

4\. Run the following **eks:node-bootstrapper** command to confirm that the kubelet has the required role-based access control (RBAC) system permissions to submit the certificate signing request (CSR):
    
    
    $ kubectl get clusterrole eks:node-bootstrapper -o yaml
    apiVersion: rbac.authorization.k8s.io/v1

The output looks similar to the following one:
    
    
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRole","metadata":{"annotations":{},"labels":{"eks.amazonaws.com/component":"node"},"name":"eks:node-bootstrapper"},"rules":[{"apiGroups":["certificates.k8s.io"],"resources":["certificatesigningrequests/selfnodeserver"],"verbs":["create"]}]}
      creationTimestamp: "2021-11-09T10:07:42Z"
      labels:
        eks.amazonaws.com/component: node
      name: eks:node-bootstrapper
      resourceVersion: "199"
      uid: da268bf3-31a3-420a-9a71-414229437b7e
    rules:
    - apiGroups:
      - certificates.k8s.io
      resources:
      - certificatesigningrequests/selfnodeserver
      verbs:
      - create

The required RBAC permissions include the following attributes:
    
    
    - apiGroups: ["certificates.k8s.io"]
    resources: ["certificatesigningrequests/selfnodeserver"]
    verbs: ["create"]

5\. Run the following command to check if the cluster role **eks:node-bootstrapper** is bound to **system:bootstrappers** and **system:nodes**. This allows the kubelet to submit and rotate the serving certificate for itself.
    
    
    $ kubectl get clusterrolebinding eks:node-bootstrapper -o yaml
    apiVersion: rbac.authorization.k8s.io/v1

The output looks similar to the following one:
    
    
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"ClusterRoleBinding","metadata":{"annotations":{},"labels":{"eks.amazonaws.com/component":"node"},"name":"eks:node-bootstrapper"},"roleRef":{"apiGroup":"rbac.authorization.k8s.io","kind":"ClusterRole","name":"eks:node-bootstrapper"},"subjects":[{"apiGroup":"rbac.authorization.k8s.io","kind":"Group","name":"system:bootstrappers"},{"apiGroup":"rbac.authorization.k8s.io","kind":"Group","name":"system:nodes"}]}
      creationTimestamp: "2021-11-09T10:07:42Z"
      labels:
        eks.amazonaws.com/component: node
      name: eks:node-bootstrapper
      resourceVersion: "198"
      uid: f6214fe0-8258-4571-a7b9-ff3455add7b9
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: eks:node-bootstrapper
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:bootstrappers
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:nodes

* * *

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
