Original URL: <https://repost.aws/knowledge-center/eks-fargate-increase-ulimit-values>

# How do I increase the nofile and nproc limits for AWS Fargate pods in Amazon EKS?

I want to increase the nofile and nproc limits for AWS Fargate pods in Amazon Elastic Kubernetes Service (Amazon EKS).

## Short description

When you run applications on Fargate, you might receive one of the following errors related to your [ulimit settings](<https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_Ulimit.html>) on your Fargate pods:

  * Too many open files.
  * Out of threads error OR runtime: failed to create new OS thread.
  * No resources available to create the process.



To increase the **nofile** and **nproc** limits, use either the **bash** command, **sh** command, or an **Init container**.

**Note:** You can't configure **ulimit** settings for Fargate pods. The default **nofile** and **nproc** soft limit is **1024** and the hard limit is **65535**. For more information, see [AWS Fargate considerations](<https://docs.aws.amazon.com/eks/latest/userguide/fargate.html#fargate-considerations>).

## Resolution

To launch Fargate pods on Amazon EKS, complete the following steps:

  1. Create a Fargate pod execution role.
  2. Create a Fargate profile for your cluster.
  3. Update the coreDNS.



For more information, see [Getting started with AWS Fargate using Amazon EKS](<https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html>).

### Use the bash command

To use the **bash** command to increase the **nofile** and **nproc** limits, complete the following steps:

  1. Run the following sample pod manifest:  
**Note:** Replace **example-nofile-limit** and **example-nproc-limit** with your new **nofile** and **nproc** limits between **1024** and **65535**.
    
        apiVersion: v1
    kind: Pod
    metadata:
      name: ubuntu
      namespace: fargate
      labels:
        app: ubuntu
    spec:
      containers:
      - image: ubuntu:18.04
        command: ["/bin/bash", "-c", "echo 'ulimit -Sn example-nofile-limit' >> /root/.bashrc && echo 'ulimit -Su example-nproc-limit' >> /root/.bashrc && sleep 100"]
        imagePullPolicy: IfNotPresent
        name: ubuntu-test
      restartPolicy: Always

  2. Apply the preceding manifest to create a new pod in the Fargate namespace:  
**Note:** Replace **example-file-name** with the file name of the preceding pod manifest.
    
        kubectl apply -f example-file-name

  3. When the pod is in a running state, run the following command to verify the new **nofile** and **nproc** limits:
    
        ~ % kubectl exec -it ubuntu -n fargate -- /bin/bash

Example output:
    
        root@ubuntu:/# ulimit -a
    core file size (blocks, -c) unlimited
    data seg size (kbytes, -d) unlimited
    scheduling priority (-e) 0
    file size (blocks, -f) unlimited
    pending signals (-i) 30446
    max locked memory (kbytes, -l) unlimited
    max memory size (kbytes, -m) unlimited
    open files (-n) example-nofile-limit
    pipe size (512 bytes, -p) 8
    POSIX message queues (bytes, -q) 819200
    real-time priority (-r) 0
    stack size (kbytes, -s) 10240
    cpu time (seconds, -t) unlimited
    max user processes (-u) example-nproc-limit
    virtual memory (kbytes, -v) unlimited
    file locks (-x) unlimited
    root@ubuntu:/# ulimit -Sn
    example-nofile-limit
    root@ubuntu:/# ulimit -Su
    example-nproc-limit




### Use the sh command

To use the **sh** command to increase the **nofile** and **nproc** limits, complete the following steps:

  1. Run the following sample pod manifest:  
**Note:** Replace **example-nofile-limit** and **example-nproc-limit** with your new **nofile** and **nproc** limits.
    
        apiVersion: v1
    kind: Pod
    metadata:
      name: alpine
      namespace: fargate
      labels:
        app: alpine
    spec:
      containers:
      - image: alpine:latest
        command: ["sh", "-c", "echo 'ulimit -Sn example-nofile-limit' >> /etc/.shrc && echo 'ulimit -Su example-nproc-limit' >> /etc/.shrc && sleep 100"]
        imagePullPolicy: IfNotPresent
        name: alpine
        env: 
        - name: ENV
          value: /etc/.shrc
      restartPolicy: Always

  2. When the pod is in a running state, run the following command to verify the new **nofile** and **nproc** limits:
    
        ~ % kubectl exec -it alpine -n fargate -- sh

Example output:
    
        / # ulimit -a
    core file size (blocks) (-c) unlimited
    data seg size (kb) (-d) unlimited
    scheduling priority (-e) 0
    file size (blocks) (-f) unlimited
    pending signals (-i) 30446
    max locked memory (kb) (-l) unlimited
    max memory size (kb) (-m) unlimited
    open files (-n) example-nofile-limit
    POSIX message queues (bytes) (-q) 819200
    real-time priority (-r) 0
    stack size (kb) (-s) 10240
    cpu time (seconds) (-t) unlimited
    max user processes (-u) example-nproc-limit
    virtual memory (kb) (-v) unlimited
    file locks (-x) unlimited




### Use Init containers

If you don't want to run the **sh** command in the main container, then use an **Init container** to run the same command. For more information, see [Init containers](<https://kubernetes.io/docs/concepts/workloads/pods/init-containers/>) on the Kubernetes website.

To use an **Init container** to increase the **nofile** and **nproc** limits, complete the following steps:

  1. Run the following sample pod manifest:  
**Note:** Replace **example-nofile-limit** and **example-nproc-limit** with your new **nofile** and **nproc** limits.
    
        apiVersion: v1
    kind: Pod
    metadata:
      name: alpine
      namespace: fargate
      labels:
        app: alpine
    spec:
      containers:
      - name: alpine
        image: alpine:latest
        imagePullPolicy: IfNotPresent
        command: ['sh', '-c', 'echo The app is running! && sleep 3600']
        env: 
        - name: ENV
          value: /etc/.shrc
        volumeMounts:
          - name: data
            mountPath: /etc
      initContainers:
      - name: init
        image: alpine:latest
        command: ["sh", "-c", "echo 'ulimit -Sn example-nofile-limit' >> /etc/.shrc && echo 'ulimit -Su example-nproc-limit' >> /etc/.shrc && sleep 10"]
        volumeMounts:
          - name: data
            mountPath: /etc
      volumes:
        - name: data
          emptyDir: {}
      restartPolicy: Always

  2. When the pod is in a running state, run the following command to verify the new **nofile** and **nproc** limits:
    
        ~ % kubectl exec -it alpine -n fargate -- sh

Example output:
    
        ~ # env
    KUBERNETES_SERVICE_PORT=443
    KUBERNETES_PORT=tcp://10.100.0.1:443
    HOSTNAME=alpine
    SHLVL=1
    HOME=/
    ENV=/etc/.shrc
    ~ # ulimit -a
    core file size (blocks) (-c) unlimited
    data seg size (kb) (-d) unlimited
    scheduling priority (-e) 0
    file size (blocks) (-f) unlimited
    pending signals (-i) 30446
    max locked memory (kb) (-l) unlimited
    max memory size (kb) (-m) unlimited
    open files (-n) example-nofile-limit
    POSIX message queues (bytes) (-q) 819200
    real-time priority (-r) 0
    stack size (kb) (-s) 10240
    cpu time (seconds) (-t) unlimited
    max user processes (-u) example-nproc-limit
    virtual memory (kb) (-v) unlimited
    file locks (-x) unlimited




* * *

Topics

[Serverless](<https://repost.aws/topics/TA4h-jxxJrRJStoIIHfQySkA/serverless>)[Containers](<https://repost.aws/topics/TAgOdRefu6ShempO3dWPEofg/containers>)

Tags

[AWS Fargate](<https://repost.aws/tags/TAdywHX42FRtu3_LYJXB0FJw/aws-fargate>)[Amazon Elastic Kubernetes Service](<https://repost.aws/tags/TA4IvCeWI1TE66q4jEj4Z9zg/amazon-elastic-kubernetes-service>)

Language

English
