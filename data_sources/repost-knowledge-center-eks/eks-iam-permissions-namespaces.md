Original URL: <https://repost.aws/knowledge-center/eks-iam-permissions-namespaces>

# How do I manage permissions across namespaces for IAM users in an Amazon EKS cluster?

I want to manage user permissions for my AWS Identity and Access Management (IAM) users across namespaces in my Amazon Elastic Kubernetes Service (Amazon EKS) cluster.

## Short description

To manage user permissions across namespaces in an Amazon EKS cluster, complete the following steps:

  1. Create an IAM role for the members of your organization to assume.
  2. Create a Kubernetes role-based access control (RBAC) role (**Role**) and role binding (**RoleBinding**) for your cluster. For more information, see [Using RBAC authorization](<https://kubernetes.io/docs/reference/access-authn-authz/rbac/>) on the Kubernetes website.
  3. Use the **aws-auth** ConfigMap to map the IAM roles to the RBAC roles and groups.



**Note:** When an IAM user or role creates a cluster, only this IAM identity's ARN is added to the **aws-auth** ConfigMap and has **system:masters** permissions. This means that only the cluster creator can add more users or roles to the **aws-auth** ConfigMap.

## Resolution

**Note:** If you receive errors when you run AWS Command Line Interface (AWS CLI) commands, then see [Troubleshoot AWS CLI errors](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-troubleshooting.html>). Also, make sure that [you're using the most recent AWS CLI version](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>).

### Create an IAM role that members of your organization can assume

Create an IAM role to give members of your organization access to a namespace:

  1. [Create a role to delegate permissions to an IAM user](<https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html>).

  2. To verify that a user has permission to assume the IAM role, [configure the AWS CLI](<https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html>). Then, run the following command from that user's workstation:
    
        $ aws sts assume-role --role-arn arn:aws:iam::yourAccountID:role/yourIAMRoleName --role-session-name abcde{
        "Credentials": {
            "AccessKeyId": "yourAccessKeyId",
            "SecretAccessKey": "yourSecretAccessKey",
            "SessionToken": "yourSessionToken",
            "Expiration": "2020-01-30T01:57:17Z"
        },
        "AssumedRoleUser": {
            "AssumedRoleId": "yourAssumedRoleId",
            "Arn": "arn:aws:iam::yourAccountID:role/yourIAMRoleName"
        }
    }

**Note:** Replace **yourAccessKeyId** , **yourSecretAccessKey** , **yourSessionToken** , **yourAssumedRoleId** , **yourAccountID** , and **yourIAMRoleName** with your values.

  3. Update the **kubeconfig** file to configure the IAM user's **kubectl** to always use the role when it accesses the Kubernetes API:
    
        $ aws eks update-kubeconfig --name yourClusterName --role-arn arn:aws:iam::yourAccountID:role/yourIAMRoleName

**Note:** Replace **yourClusterName** , **yourAccountID** , and **yourIAMRoleName** with your values.




### Create a Kubernetes RBAC role and role binding for your cluster

**Important:** You must complete the following steps from a workstation that's configured to access Kubernetes. You must be a cluster creator or an [IAM identity](<https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html>) that already has access through the **aws-auth** ConfigMap. The IAM role doesn't have access to the cluster yet.

Bind a cluster role (**ClusterRole**) to a role binding. An RBAC role and role binding are Kubernetes namespaced resources. However, you can't bind a role to a cluster role binding (**ClusterRoleBinding**).

  1. Run the following command to list all built-in cluster roles and bind the cluster role admin to a role binding for the namespace:
    
        $ kubectl get clusterrole

  2. Run the following command to see the permissions that are associated with the cluster role admin:
    
        $ kubectl describe clusterrole admin

  3. Create a namespace that's named **test** to grant access to the IAM users as part of the IAM group:  
**Note:** If you choose a different name, then replace the values for the **namespace** parameter To use an existing namespace, proceed to step 4.
    
        $ kubectl create namespace test

  4. To create a Kubernetes RBAC role, copy the following code into a new YAML file (for example, **role.yaml**):
    
        kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: k8s-test-role
      namespace: test
    rules:
      - apiGroups:
          - ""
          - "apps"
          - "batch"
          - "extensions"
        resources:
          - "configmaps"
          - "cronjobs"
          - "deployments"
          - "events"
          - "ingresses"
          - "jobs"
          - "pods"
          - "pods/attach"
          - "pods/exec"
          - "pods/log"
          - "pods/portforward"
          - "secrets"
          - "services"
        verbs:
          - "create"
          - "delete"
          - "describe"
          - "get"
          - "list"
          - "patch"
          - "update"

**Note:** The Kubernetes RBAC role allows users to perform all the actions in the **verbs** section.

  5. Run the following command to create the RBAC role:
    
        $ kubectl apply -f role.yaml

  6. Create a Kubernetes role binding. Copy the following code into a new YAML file (for example, **rolebinding.yaml**):
    
        kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: k8s-test-rolebinding
      namespace: test
    subjects:
    - kind: User
      name: k8s-test-user
    roleRef:
      kind: Role
      name: k8s-test-role
      apiGroup: rbac.authorization.k8s.io

**Note:** The role binding is a namespaced resource that binds the RBAC role in the **roleRef** section to the user in the **subjects** section. You don't need to create the **k8s-test-user** user because Kubernetes doesn't have a **user** resource type.

  7. Run the following command to create the RBAC role binding:
    
        $ kubectl apply -f rolebinding.yaml




### Use the aws-auth ConfigMAP to map the IAM role to the RBAC role and group 

Run the following command to associate the **yourIAMRoleName** IAM role with the **k8s-test-user** Kubernetes user:
    
    
    $ eksctl create iamidentitymapping --cluster yourClusterName --arn arn:aws:iam::yourAccountID:role/yourIAMRoleName --username k8s-test-user

**Note:** Replace **yourClusterName** , **yourAccountID** , and **yourIAMRoleName** with your values.

### Test the access to the namespace

  1. Run the following command to test access to the **test** namespace:
    
        $ kubectl create job hello -n test --image=busybox -- echo "Hello World"

**Note:** The preceding command creates a job that uses the **k8s-test-role** RBAC role that you created.
  2. Run the following commands to check the pod and job in the **test** namespace:
    
        $ kubectl get job -n testNAME    COMPLETIONS   DURATION   AGE
    hello   1/1           4s         15s
    
    $ kubectl get pods -n test
    NAME          READY   STATUS      RESTARTS   AGE
    hello-tpjmf   0/1     Completed   0          2m34s




* * *

Topics

[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
