# KOrthweb - Orthanc deployment on Kubernetes
KOrthweb is a web deployment of Orthanc on Kubernetes. The steps in this instruction, can be performed on Elastic Kubernetes Service (EKS by AWS), Azure Kubernetes Service (AKS by Azure), or Google Kubernetes Engine (GKE by GCP). 

## Prerequisite
Assuming deployment is performed from MacOS, the following deployment tools must be installed and configured. All of them support both Linux and Windows, but have not been extensively tested. 

### Deployment Tools
We need these tools to complete installation. Some are pre-installed on cloud shell from each provider.
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): interact with the Kubernetes cluster. Once we provision a Kubernetes cluster, we can use cloud provider's CLI tool to update kubectl context. However, if is helpful to know how to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) for kubectl manually.
* [openssl](https://www.openssl.org/): if you do not have an existing key and certificate, and you need to create self-signed ones. Use OpenSSL, which is usually installed by default on MacOS or Linux.
* [helm](https://helm.sh/docs/intro/install/): To install postgres database, we leverage existing package (helm chart) to deploy database from a single command.  

### Platform CLI
Depending on the cloud platform, we need one or more of the CLI tools. Please refer to their respective instructions to install  and configure them. 
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html): If we use EKS, we rely on awscli to connect to resources in AWS. The credentials for programatic access is stored under profile. Instruction is [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). 
* [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html): If we use EKS, we describe cluster specification in a YAML template, and eksctl will generate a CloudFormation template so awscli can use it to create resources in AWS.
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/): If we use AKS, we use az cli to interact with Azure. Alternatively, we can use [Azure CloudShell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), which has Azure CLI, kubectl, and helm pre-installed.
* [gcloud](https://cloud.google.com/sdk/docs/install): If we use GKE, we use gcloud as client tool. Note that we can simply use GCP's [cloud shell](https://cloud.google.com/shell), which has gcloud and kubectl pre-installed and pre-configured.

## Kubernetes cluster

In this section, we build Kubernetes cluster and update local kubectl context so that we can continue with deployment steps below. We also cover how to delete the cluster.
### AWS EKS

On AWS, we use eksctl with a template to create EKS cluster,  The template cluster.yaml is located in eks directory.
```sh
eksctl create cluster -f cluster.yaml --profile default
```
The cluster provisioning may take as long as 20 minutes.  Then we can update kubectl configuration pointing to the cluster, using AWS CLI:
```sh
aws eks update-kubeconfig --name orthweb-cluster --profile default --region us-east-1 
```
At the end, we can delete the cluster with eksctt
```sh
eksctl delete cluster -f cluster.yaml --profile default
```
### AKS
To create a cluster, assuming resource group name is AutomationTest, and cluster name is orthCluster
```sh
az aks create -g AutomationTest -n orthCluster --node-count 3 --enable-addons monitoring --generate-ssh-keys --tags Owner=MyOwner
```
Then we can update local kubectl context with the following command:
```sh
az aks get-credentials --resource-group AutomationTest --name orthCluster
```
If we are done with the test, we delete the cluster:
```sh
az aks delete -g AutomationTest -n orthCluster
```

### GCP GKE
On GCP, we use the following commands from CloudShell to provision a GKE cluster, then update kubectl configuration pointing to the cluster.
```sh
gcloud config set compute/zone us-east1-b
gcloud container clusters create orthcluster --num-nodes=3
```
Then we can update kubectl context:
```sh
gcloud container clusters get-credentials orthcluster
```
To delete the cluster
```sh
gcloud container clusters delete orthcluster
```

## Deploy Orthanc Manually 
Once K8s cluster is configured, we can start deploying Orthanc. The files required for manual deployment is located in k8s subdirectory.

### Prepare Configuration
If we don't already have key and certificates, let's generate key and certificate for CA, and use it to sign a certificate for our site.
```sh
openssl req -x509 -sha256 -newkey rsa:4906 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Test Cert Authority'
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=orthweb.digihunch.com'
openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
```
Then we can import configuration (including certificates, keys and application configurations) into Kubernetes cluster. 
```sh
kubectl apply -f configmap.yaml
kubectl -n orthweb create secret tls tls-orthweb --cert=server.crt --key=server.key
```
### Deploy Database
The install of database will require an initialization script (stored in ConfigMap orthanc-dbinit from the last step). Before doing that, we want to make sure helm knows where to pick up helm chart for Postgres installation, by adding repo URL:
```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
```
Then we can initialize postgres database in HA, with custom options as below:
```sh
helm install postgres-ha bitnami/postgresql-ha \
     --create-namespace --namespace orthweb \
     --set pgpool.tls.enabled=true \
     --set pgpool.tls.certificatesSecret=tls-orthweb \
     --set pgpool.tls.certFilename=tls.crt \
     --set pgpool.tls.certKeyFilename=tls.key \
     --set postgresql.initdbScriptsCM=orthanc-dbinit
```
Monitor the service and deploy status until all Pods are up. It usually takes a couple minutes.
```sh
kubectl get all -n orthweb
```

### Deploy Application
The application deployment is done with a deployment object and a service object (load balancer type):
```sh
kubectl apply -f web-deploy.yaml
kubectl apply -f web-service.yaml
```
The bottom command brings up a network load balancer, with 8042 (HTTPS) and 4242 (DICOM TLS) ports open. The web-svc status has loadBalancer field under status, which indicates the dns name of load balancer. The DNS name may take a couple minutes to become resolvable. The IP address can be added to local host file (e.g. /etc/hosts for Mac and Linux) like this:
```
3.232.159.192 orthweb.digihunch.com 
```
The load balancer may take a couple minutes to come up.

### Validation
we use curl and echoscu (installed as dcmtk brew package) to validate. Assuming the DNS resolution is working (either by editing /etc/hosts locally or, by actually adding an A record in DNS)
```sh
curl -k -X GET https://orthweb.digihunch.com:8042/app/explorer.html -I -u orthanc:orthanc
echoscu -v orthweb.digihunch.com 4242 --anonymous-tls +cf ca.crt
storescu -v -aec ORTHANC --anonymous-tls +cf ca.crt orthweb.digihunch.com 4242 ~/Downloads/CR.dcm
```
The stdout from DICOM C-Echo interaction looks like this:
```
I: Requesting Association
I: Association Accepted (Max Send PDV: 16372)
I: Sending Echo Request (MsgID 1)
I: Received Echo Response (Success)
I: Releasing Association
```
The stdout from DICOM C-Store interaction looks like this:
```
I: checking input files ...
I: Requesting Association
I: Association Accepted (Max Send PDV: 16372)
I: Sending file: /Users/digihunch/Downloads/CR.dcm
I: Converting transfer syntax: Little Endian Implicit -> Little Endian Implicit
I: Sending Store Request (MsgID 1, CR)
XMIT: ....................................................................................................................................................................................................................................................................................................................................................................................
I: Received Store Response (Success)
I: Releasing Association
``` 

## Deploy Orthanc in a single command using helm chart
The helm chart is stored in orthanc sub-directory


### Clean up
If this deployment is for testing only, it is important to clean up environment by deleting the cluster at the end. The steps to delete cluster are under the section Kubernetes Cluster above. The deletion may take a couple minutes.

### Troubleshooting Tips
If Pod does not come to Running status, and is stuck with CreateContainerConfigError, check Pod status details with -o yaml. Consider configuration error such as passing secret data to env variable. 
```sh
kubectl -n orthweb get po web-dpl-6ddb587885-xxxx -o yaml
```
If Pod continues to fail, check postgres connectivity from within the Pod. You might need to comment out the args so you can ssh into the Pod and run the followings:
```sh
export PGPASSWORD=$DB_PASSWORD && apt update && apt install postgresql postgresql-contrib
psql --host=$DB_ADDR --port $DB_PORT --username=$DB_USERNAME sslmode=require
```
For a manual test from kubectl client, use port forwarding: 
```sh
kubectl -n orthweb port-forward service/web-svc 8042:8042
curl -k -X GET https://0.0.0.0:8042/app/explorer.html -I -u orthanc:orthanc
```


### Notes
1. How container [args](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/) work.

2. How http authentication works in [readiness probe](https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes).

3. Postgres Container Documentation (postgresql.initdbScriptsCM takes files with sql extension, while pgpool.initdbScriptsCM doesn't, according to [this](https://artifacthub.io/packages/helm/bitnami/postgresql-ha)
