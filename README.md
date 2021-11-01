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
## Test the site after automatic deployment
The helm chart by default does a lot of automation, including the creation of certificates for the following three domain name. The helm chart also creates a public facing load balancer. we need to collect some information before validation.
db.orthweb.com
dcm.orthweb.com
web.orthweb.com

The second and third DNS names are external facing. To validate the site, we apply a trick to artificially point the DNS name to the public IP address of load balancer.

1. Find out the DNS address of load balancer
```sh
kubectl get svc 
``` 
Jot down the EXTERNAL-IP of orthweb-orthanc.  Suppose we get xyz.elb.us-east-1.amazonaws.com

2. find out the public IP of load balancer by dns name
```sh
nslookup xyz.elb.us-east-1.amazonaws.com
```
Jot down the IP address. Suppose we get 123.22.143.244

3. Edit the host file of your client laptop, add the line below to the bottom of /etc/hosts
123.22.143.244 dicom.orthweb.com
123.22.143.244 web.orthweb.com
with the steps above, we're making sure dicom.orthweb.com resolves to the correct public IP (effective on the testing client)

4. Test the port from the test client
```sh
nc -vz dicom.orthweb.com 4242
nc -vz web.orthweb.com 8042
```
Both should report succeeded.

5. From kubernetes secret store, pull out the certificate for dicom.orthweb.com into a file for later use
```sh
kubectl get secret dcm.orthweb.com -o jsonpath='{.data}' | jq -r '."ca.crt"' | base64 --decode > dcm.orthweb.com.ca.crt
```

6. To test web connection, simply browse to https://web.orthweb.com:8042/app/explorer.html from browser and use default username and password. Alternatively, use curl command to ensure 200 code is returned:
```sh
curl -k -X GET https://web.orthweb.com:8042/app/explorer.html -I -u orthanc:orthanc
```

7. Validate DICOm connectivity. We need to install dcmtk (use home brew to install) and tell echoscu to present the cert that we just generated above.
```sh
echoscu -v dicom.orthweb.com 4242 --anonymous-tls +cf dcm.orthweb.com.ca.crt
```
The response should say Received Echo Response (Success)

8. Send DICOM image
```sh
storescu -v -aec ORTHANC --anonymous-tls +cf dcm.orthweb.com.ca.crt web.orthweb.com 4242 ~/Downloads/CR.dcm
```
The response should say Received Store Response (Success) and the study should be accessible from Orthanc web portal.

