# Kubernetes Cluster

Building a production grade Kubernetes cluster is a professional effort that is beyond the scope of this project. Skip this section if you already have a sandbox cluster. Otherwise, 

## Sandbox cluster

The [CloudKube](https://github.com/digihunch/cloudkube) project provides Terraform templates to create Kubernetes cluster along with networking layer in Azure and AWS. These clusters represents what a production cluster looks like in real life and it takes about 30 minutes to deploy. 

For quick evalucation of Kubernetes workload, developers builds their own sandbox Kubernetes cluster running on MacBook or PC. There are many ways to build a sandbox cluster. 

I do not recommend the Kubernetes distro that came with Docker desktop. It is a single node and as of aug 2021 it does not use containerd as CRI. Read [this](https://www.digihunch.com/2021/08/docker-desktop-a-single-node-kubernetes-cluster/) post about the details.

Refer to the [real-quicK-cluster](https://github.com/digihunch/real-quicK-cluster) project for more about how to set up a sandbox cluster depending on your operating system. Refer to [this](https://www.digihunch.com/2021/09/single-node-kubernetes-cluster-minikube/) post for the differences between options.

## Storage

Kubernetes platform hosts applications but it does not by itself provide storage. It needs to integrate with external storage services via Container Storage Interface. 

The Osimis image includes Orthanc [S3 plugin](https://book.orthanc-server.com/plugins/object-storage.html), which allows to store images as objects. Alternatively, you can store images on file systems mounted to Pods.

With S3 plugin, you can either use Amazon S3, or any self-hosted S3-compatible object storage. [MinIO](https://min.io/) is a good choice. The configuration is not covered in this guide.

For file storage, you will need to configure storage classes and persistent volumes. In each cloud platform, there is some pre-built storage classes to consider. For example, [this](https://www.digihunch.com/2022/07/kubernetes-storage-on-azure-1-of-3-built-in-storage-and-nfs/) post discusses the storage options on Azure Kubernetes.

Another option is to consider an SDS (software defined storage) layer. For SDS-based storage solution, you may use a proprietary solution such as Portworx, or an open-source self-hosted alternative such as Ceph by Rook. [Here](https://www.digihunch.com/2022/08/kubernetes-storage-on-azure-2-of-3-portworx/) is a post that discusses the setup on Azure Kubernetes.

## Database

In Korthweb, Orthanc connects to PostgreSQL database. Korthweb hosts database on Kubernetes. Database is a stateful workload and maintaining it on Kubernetes is involving. For that sake, many favour the alternative hosting models for database: using a managed database service from cloud provider. Refer to blog post [Hosting database on Kubernetes](https://www.digihunch.com/2022/05/hosting-database-on-kubernetes/) for more pros and cons of this topic.

In general, if your team does not have the resource to administer the database (e.g. configure replication, expanding, configure storage, backup, patching, updates, etc), you should consider managed database service by cloud provider, such as Azure database for PostgreSQL, Amazon RDS/Aurora PostgreSQL or GCP Cloud SQL for PostgreSQL. 

## Limitation

The context provided above is to raise awareness so that the complextity of system architecture is not underestimated. Being a demo project, the Korthweb deployment has taken some "happy paths" and this section explains what the simplifcations are.

In terms of database, Korthweb configures Orthanc to store images in PostgreSQL database by setting EnableStorage to true under PostgreSQL plugin configuration. In production, it is better to store images separately using object storage or persistent volumes. 
