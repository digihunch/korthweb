

We need a Kubernetes cluster as the platform to run Helm Chart. Depending on your use case, consider the following options for Kubernetes cluster:
| Use case | Description | How to create |
|--|--|--|
| Playground | Multi-node cluster on single machine to start instantly for POC.| Use Minikube on MacOS or kind on WSL2. Check out my [post](https://www.digihunch.com/2021/09/single-node-kubernetes-cluster-minikube/) for the reason for this choice. |
| Demo | Multi-node cluster on public cloud platform such as EKS on AWS, AKS on Azure or GKE on GCP. | CLI tools by the cloud vendor can typically handle this level of complexity. Working instructions are provided for reference in the [cluster](https://github.com/digihunch/korthweb/blob/main/cluster/README.md)  directory of this project. |
| Professional | Clusters on private networks in public cloud or private platform for test and production environments.  | The cluster infrastructure should be managed as IaC (Infrastructure as Code) specific to your environment. Reference implementation provided in [CloudKube](https://github.com/digihunch/cloudkube) project. Contact [DigiHunch](https://www.digihunch.com/contact/) for professional service to customize the cluster.|



### Platform CLI
Depending on the cloud platform, we need one or more of the CLI tools. Please refer to their respective instructions to install  and configure them. 
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html): If we use EKS, we rely on awscli to connect to resources in AWS. The credentials for programatic access is stored under profile. Instruction is [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). 
* [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html): If we use EKS, we describe cluster specification in a YAML template, and eksctl will generate a CloudFormation template so awscli can use it to create resources in AWS.
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/): If we use AKS, we use az cli to interact with Azure. Alternatively, we can use [Azure CloudShell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview), which has Azure CLI, kubectl, and helm pre-installed.
* [gcloud](https://cloud.google.com/sdk/docs/install): If we use GKE, we use gcloud as client tool. Note that we can simply use GCP's [cloud shell](https://cloud.google.com/shell), which has gcloud and kubectl pre-installed and pre-configured.


## Kubernetes cluster
### Kind
```sh
kind create cluster --config=kind-config.yaml
```
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
