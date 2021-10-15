# Korthweb - Orthanc deployment on Kubernetes
Korthweb is a web deployment of Orthanc on Kubernetes. 

## Prerequisite
We need a Kubernetes cluster. A few options to consider are:
* A single machine cluster (e.g. docker-desktop, minikube, kind)
* EKS (Elastic Kubernetes Service) cluster on AWS
* AKS (Azure Kubernetes Service) cluster on Azure
* GKE (Google Kubernetes Engine) on GCP

A K8s cluster on a single machine is easy to configure but there are some details to consider for choosing the right tool. On that, I wrote a blog [post](https://www.digihunch.com/2021/09/single-node-kubernetes-cluster-minikube/) but the takeaway is: use Minikube on Mac, and use Kind with Docker desktop on Windows 10 WSL2. For cloud platforms, refer to [this](https://github.com/digihunch/korthweb/blob/main/cluster/README.md) instruction in *cluster* directory. Once the cluster is created and can be connected from kubectl, you can download this project directory to start. 

This repo consists of two methods of deployment:
* **Automatic deployment** using the helm chart defined in *orthanc* directory. With a single command, the installation is completed hassle-free, including the creation of self-signed certificates for tls connections for database, web, and dicom. The installation behaviour is customizable by parameters. The rest of this instruction is based on automatic deployment.
* **Manual deployment** using the YAML declarations to complete installation manually. This involves manual steps and requires better understanding of Kubernetes to operate. For more details, refer to [this](https://github.com/digihunch/korthweb/tree/main/manual) instruction.

### Client-side tools
We need these tools to complete installation. Some are pre-installed on cloud shell from each provider.
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): interact with the Kubernetes cluster. Once we provision a Kubernetes cluster, we can use cloud provider's CLI tool to update kubectl context. However, if is helpful to know how to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) for kubectl manually.
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes.

## Deploy Orthanc using helm
The helm chart is stored in orthanc sub-directory
```sh
helm dependency update orthanc
```
From orthweb directory, run:
```sh
helm install orthweb orthanc
```
To uninstall (and remove persistent volumes for database) 
```sh
helm uninstall orthweb && kubectl delete pvc -l app.kubernetes.io/component=postgresql && kubectl delete pvc -l app=elasticsearch-master
```
