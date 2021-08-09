# Korthweb - Orthanc deployment on Kubernetes
Korthweb is a web deployment of Orthanc on Kubernetes. 

## Prerequisite
We need a Kubernetes cluster. A few options to consider are:
* A single-node cluster (e.g. docker-desktop, minikube)
* Elastic Kubernetes Service cluster on AWS
* Azure Kubernetes Service cluster on Azure
* Google Kubernetes Engine on GCP

A [single-node cluster](https://docs.docker.com/desktop/kubernetes/#:~:text=To%20enable%20Kubernetes%20support%20and,them%20manually%20is%20not%20supported.) is fairly easy to configure. For clusters on the cloud platforms, refer to [this](https://github.com/digihunch/korthweb/blob/main/cluster/README.md) instruction in *cluster* directory. Once the cluster is created and can be connected from kubectl, you can download this project directory to start. 

The deployment project consists of two methods of deployment:
* **Automatic deployment** using the helm chart defined in *orthanc* directory. With a single command, the installation is completed hassle-free, including the creation of self-signed certificates for tls connections for database, web, and dicom. The installation behaviour is customizable by parameters. The rest of this instruction is based on automatic deployment.
* **Manual deployment** using the YAML declarations to complete installation manually. This gives you full transparency in terms of what kubernetes objects are created, but involves more steps and requires better understanding of Kubernetes. For more details, refer to [this](https://github.com/digihunch/korthweb/tree/main/manual) instruction.

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
