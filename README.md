# Korthweb - Orthanc deployment on Kubernetes
Korthweb is a web deployment of Orthanc on Kubernetes. The steps in this instruction, can be performed on Elastic Kubernetes Service (EKS by AWS), Azure Kubernetes Service (AKS by Azure), or Google Kubernetes Engine (GKE by GCP). 

## Prerequisite
The deployment project consists of two methods of deployment:
* **Single-command deployment** using the helm chart defined in *orthanc* directory
* **Manual deployment** using the YAML declarations in k8s directory

Either way, we will need a Kubernetes cluster. A few options to consider are:
* A single-node cluster (e.g. docker-desktop, minikube)
* Elastic Kubernetes Service cluster on AWS
* Azure Kubernetes Service cluster on Azure
* Google Kubernetes Engine on GCP

A [single-node cluster](https://docs.docker.com/desktop/kubernetes/#:~:text=To%20enable%20Kubernetes%20support%20and,them%20manually%20is%20not%20supported.) is fairly easy to configure. For clusters on the cloud platforms, refer to this instruction in *cluster* directory.

### Client-side tools
We need these tools to complete installation. Some are pre-installed on cloud shell from each provider.
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): interact with the Kubernetes cluster. Once we provision a Kubernetes cluster, we can use cloud provider's CLI tool to update kubectl context. However, if is helpful to know how to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) for kubectl manually.
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes.

## Deploy Orthanc using helm
The helm chart is stored in orthanc sub-directory

```sh
helm dependency update orthanc
```


To finish
