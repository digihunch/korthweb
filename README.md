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

## Deploy Orthanc in a single command using helm chart
The helm chart is stored in orthanc sub-directory

```sh
helm dependency update orthanc
```

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
