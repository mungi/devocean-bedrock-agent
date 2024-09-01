Original URL: <https://repost.aws/knowledge-center/eks-conditional-forwarder-coredns>

# How do I configure a conditional forwarder with CoreDNS in my Amazon EKS cluster?

I want to configure a conditional forwarder with CoreDNS in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

Use CoreDNS to configure a conditional forwarder for DNS queries that are sent to the domains that a customized DNS server resolves. For more information, see [Customizing DNS service](<https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/>) on the Kubernetes website.

**Important:** Before you make configuration changes to the CoreDNS Amazon EKS add-on, you must determine the settings that Amazon EKS manages. You can find this information in the [Amazon EKS add-on configuration](<https://docs.aws.amazon.com/eks/latest/userguide/add-ons-configuration.html>). When you modify a field that Amazon EKS manages, Amazon EKS can't manage the add-on. Amazon EKS might overwrite your changes when an add-on is updated.

## Resolution

The following resolution applies to CoreDNS self-managed and Amazon EKS add-on configurations.

### Configure a self-managed add-on

Run the following command to modify the CoreDNS ConfigMap and add the custom DNS conditional forwarder configuration:
    
    
    $ kubectl -n kube-system edit configmap coredns

The output looks similar to the following:
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      annotations:
      labels:
        eks.amazonaws.com/component: coredns
        k8s-app: kube-dns
      name: coredns
      namespace: kube-system
    data:
      Corefile: |
        .:53 {
            errors
            health
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :9153
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
        }
        domain-name:53 {
            errors
            cache 30
            forward . custom-dns-server
            reload
        }

**Note:** Replace **domain-name** with your domain name and **custom-dns-server** with your custom DNS server IP address.

### Configure an Amazon EKS add-on

To make the changes to the Amazon EKS managed CoreDNS add-on, complete the following steps:

  1. Open the [Amazon EKS console](<https://console.aws.amazon.com/eks/home#/clusters>).

  2. In the navigation pane, choose **Clusters**.

  3. Choose the name of your cluster.

  4. Choose the **Add-ons** tab.

  5. Select the **CoreDNS** add-on, and then choose **Edit**.

  6. On the edit page, choose the **Optional configuration settings** section. In the **Configuration values** section, add the custom DNS conditional forwarder configuration:
    
        corefile: |
        .:53 {
            errors
            health
            kubernetes cluster.local in-addr.arpa ip6.arpa {
              pods insecure
              fallthrough in-addr.arpa ip6.arpa
            }
            prometheus :9153
            forward . /etc/resolv.conf
            cache 30
            loop
            reload
            loadbalance
        }
        domain-name:53 {
            errors
            cache 30
            forward . custom-dns-server
            reload
        }

**Note:** Replace **domain-name** with your domain name and **custom-dns-server** with your custom DNS server IP address.




### Verify the domain name resolution

To verify that domain name resolution works, run the following commands:
    
    
    $ kubectl run busybox --restart=Never --image=busybox:1.28 -- sleep 3600
    $ kubectl exec busybox -- nslookup domain-name

**Note:** Replace **domain-name** with your domain name.

* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
