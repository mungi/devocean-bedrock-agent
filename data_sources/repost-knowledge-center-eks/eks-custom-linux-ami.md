Original URL: <https://repost.aws/knowledge-center/eks-custom-linux-ami>

# How do I create custom Amazon Linux AMIs for Amazon EKS?

I want to create a custom Amazon Linux Amazon Machine Image (AMI) to deploy with an Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

To create a custom Amazon Linux AMI for Amazon EKS, you must use the following:

  * The HashiCorp Packer. For more information, see [Packer Documentation](<https://developer.hashicorp.com/packer/docs>) on the HashiCorp website.
  * A build specification with resources and configuration scripts from the [Amazon EKS AMI repository on AWS GitHub](<https://github.com/awslabs/amazon-eks-ami>).



**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

## Resolution

### Install and configure Packer

To install and configure Packer, complete the following steps:

  1. [Install Packer](<https://learn.hashicorp.com/tutorials/packer/get-started-install-cli?in=packer/aws-get-started>) from the HashiCorp website.
  2. Configure your AWS account credentials to allow Packer to make calls to AWS API operations on your behalf. Use static credentials such as a secret key and secret access key, an environment variable, or shared credential files. You can also use an AWS Identity and Access Management (IAM) role for Amazon Elastic Compute Cloud (Amazon EC2).



For more information about AWS credentials for Packer, see [Authentication](<https://www.packer.io/docs/builders/amazon.html#authentication>) and [IAM task or instance role](<https://www.packer.io/docs/builders/amazon.html#iam-task-or-instance-role>) on the HashiCorp website.

### Clone the Amazon EKS AMI repository

To clone the Amazon EKS AMI repository to your workstation, run the following command:
    
    
    $ git clone https://github.com/awslabs/amazon-eks-ami && cd amazon-eks-ami

Packer is performed through a series of makefile targets with eks-worker-al2.json as the build specification. For more information, see [eks-worker-al2.json](<https://github.com/awslabs/amazon-eks-ami/blob/master/eks-worker-al2.json>) on the AWS Labs GitHub repository. The build process uses the **amazon-ebs** Packer builder and launches an instance. The Packer shell provisioner runs the **install-worker.sh** script on the instance to install software and perform other configuration tasks. For more information, see [Amazon Elastic Block Store (Amazon EBS)](<https://developer.hashicorp.com/packer/integrations/hashicorp/amazon/latest/components/builder/ebs>) and [Shell provisioner](<https://developer.hashicorp.com/packer/docs/provisioners/shell>) on the HashiCorp website. The Packer creates an AMI from the instance and terminates the instance after the AMI is created.

### Provide a custom source AMI

To configure a custom source AMI, set the **source_ami_id** , **source_ami_owners** , and **aws_region** variables in the **eks-worker-al2.json** Packer configuration file. Example:
    
    
    "source_ami_id": "SOURCE_AMI_ID",      # Enter the ID of your source image"source_ami_owners": "AWS_ACCOUNT_ID", # Enter the account where this image is stored
    "aws_region": "AWS_DEFAULT_REGION",    # Enter the AWS Region of the source AMI

To provide custom worker binaries, complete the steps in the **(Optional) Provide your own Kubernetes binaries** section.

To build the image with default Kubernetes binaries, complete the steps in the **Build an Amazon EKS worker AMI with default binaries** section.

### (Optional) Provide your own Kubernetes binaries

When Packer provisions the instance, binaries are downloaded by default from the Amazon EKS public Amazon Simple Storage Service (Amazon S3) bucket **amazon-eks** in **us-west-2**. For more information, see the [install-worker.sh file](<https://github.com/awslabs/amazon-eks-ami/blob/master/scripts/install-worker.sh>) on the AWS Labs GitHub repository. To provide your own Kubernetes binaries, complete the following steps:

  1. To examine the available binaries that are provided in the default bucket, run the following AWS CLI command. Replace **amazon-eks** , **kubernetes_version** , **kubernetes_build_date** , and **arch** with your values:
    
        $ aws s3 ls s3://amazon-eks $ aws s3 ls s3://amazon-eks/kubernetes_version/kubernetes_build_date/bin/linux/arch/

**Important:** To download your own binaries to the worker node as it provisions, mirror the **amazon-eks** bucket folder structure that's used in the **install-worker.sh** script.
  2. After your binaries are prepared, use the AWS CLI to copy the binaries your Amazon S3 bucket.  
The following example uses a custom **kubelet** binary. Replace **my-custom-bucket** , **amazon-eks** , **kubernetes_version** , **kubernetes_build_date** , and **arch** with your values:
    
        $ aws s3 cp kubelet s3://my-custom-bucket/kubernetes_version/kubernetes_build_date/bin/linux/arch/kubelet

**Important:** You must provide all the binaries that are listed in the default **amazon-eks** bucket for a specific **kubernetes_version** , **kubernetes_build_date** , and **arch** combination. These binaries must be accessible through the IAM credentials that you configured.



### Build an Amazon EKS worker AMI with custom binaries

To start the build process, use the source AMI that's configured in **eks-worker-al2.json** to invoke **make** with the parameters. Example
    
    
    $ make k8s \    binary_bucket_name=my-custom-bucket \
        binary_bucket_region=eu-west-1 \
        kubernetes_version=1.14.9 \
        kubernetes_build_date=2020-01-22

**Note:** Confirm that the **binary_bucket_name** , **binary_bucket_region** , **kubernetes_version** , and **kubernetes_build_date** parameters match the path to your binaries in Amazon S3.

### Build an Amazon EKS worker AMI with default binaries

To build the Amazon EKS worker AMI with a custom base AMI and the default (latest) Kubernetes binaries, complete the following steps:

  1. Confirm that the **eks-worker-al2.json** file is updated with the correct base AMI.
  2. Start the build process. Run the following command to provide the Kubernetes version as the parameter:
    
        $ make 1.14  # Build a Amazon EKS Worker AMI for k8s 1.14

For more advanced configurations, before you start the build, modify the configuration files in the [amazon-eks-ami](<https://github.com/awslabs/amazon-eks-ami>) from the AWS GitHub repository.



* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
