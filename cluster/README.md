# Build a Kubernetes cluster for Orthanc

We need a Kubernetes cluster as the platform to run Orthanc workload. Depending on your requirement, consider the following options for Kubernetes cluster:
| Use case | Description | How to create |
|--|--|--|
| Playground | Multi-node cluster on single machine to start instantly for POC.| Pick a technology depending on your OS. On MacOS, use Minikube; On Windows with WSL2, use kind with Docker. On Windows without WSL2, use Minikube. |
| Staging | Multi-node cluster on public cloud platform such as EKS on AWS, AKS on Azure or GKE on GCP. | CLI tools by the cloud vendor can typically handle this level of complexity. Working instructions are provided for reference in the [cluster](https://github.com/digihunch/korthweb/blob/main/cluster/README.md)  directory of this project. |
| Professional | Clusters on private networks in public cloud or private platform for test and production environments.  | The cluster infrastructure should be managed as IaC (Infrastructure as Code) specific to your environment. Reference implementation provided in [CloudKube](https://github.com/digihunch/cloudkube) project. Contact [DigiHunch](https://www.digihunch.com/contact/) for professional service to customize the cluster.|

## Create a playground cluster 
A playground cluster can usually be created on a MacBook or PC, with a tool of choice to create multi-node Kubernetes cluster locally. For more details, check out [this post](https://www.digihunch.com/2021/09/single-node-kubernetes-cluster-minikube/) . 
### Minikube
Minikube is recommended for MacOS.
1. Install hypberkit and minikube with HomeBrew
2. Create
```sh
minikube start --memory=12288 --cpus=6 --kubernetes-version=v1.20.2 --nodes 3 --container-runtime=containerd --driver=hyperkit --disk-size=150g
minikube addons enable metallb
minikube addons configure metallb
```
The last command prompt for the load balancer's IP address range. We need to provide a range based on the IP address of the host, which is routable from the host. For example, use the following command to find out the IP address of the third node:

```sh
minikube ssh -n minikube-m03 "ping host.minikube.internal -c 1"
```
If the IP address is 192.168.64.3, we can specify a range of 192.168.64.16 - 192.168.64.23 for load balancer IPs. Once a Kubernetes Service with LoadBalancer type is created, it should pick up one of the IP address from the range.

To destroy the cluster, run:
```sh
minikube stop && minikube delete
```
### Kind
Kind is recommended for Windows with WSL2. Todo: Instruction for Kind on Windows WSL2 including how to destroy.

## Create a staging cluster
Depending on the cloud platform, we need one or more of the CLI tools. Please refer to their respective instructions to install  and configure them. 
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html): If we use EKS, we rely on awscli to connect to resources in AWS. The credentials for programatic access is stored under profile. Instruction is [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). 
* [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html): If we use EKS, we describe cluster specification in a YAML template, and eksctl will generate a CloudFormation template so awscli can use it to create resources in AWS.
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/): If we use AKS, we use az cli to interact with Azure. Alternatively, we can use [Azure CloudShell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), which has Azure CLI, kubectl, and helm pre-installed.
* [gcloud](https://cloud.google.com/sdk/docs/install): If we use GKE, we use gcloud as client tool. Note that we can simply use GCP's [cloud shell](https://cloud.google.com/shell), which has gcloud and kubectl pre-installed and pre-configured.

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

## Create a production cluster
Production cluster requires some effort to design and implmenet. A good start point is the [CloudKube](https://github.com/digihunch/cloudkube) project. Alternatively, get professional service from [Digi Hunch](https://www.digihunch.com/contact/). 