# Korthweb - Orthanc deployment on Kubernetes
Korthweb is an open-source project to deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes platform. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb uses Helm for automation, and Istio for ingress and observability. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc in AWS. 

## Prerequisite
We need a Kubernetes cluster as the platform to run Helm Chart. Depending on your use case, consider the following options:
| Use case | Description | How to create |
|--|--|--|
| Playground | Multi-node cluster on single machine to start instantly for POC.| Use Minikube on MacOS or kind on WSL2. Check out my [post](https://www.digihunch.com/2021/09/single-node-kubernetes-cluster-minikube/) for the reason for this choice. |
| Demo | Multi-node cluster on public cloud platform such as EKS on AWS, AKS on Azure or GKE on GCP. | CLI tools by the cloud vendor can typically handle this level of complexity. Working instructions are provided for reference in the [cluster](https://github.com/digihunch/korthweb/blob/main/cluster/README.md)  directory of this project. |
| Professional | Clusters on private networks in public cloud or private platform for test and production environments.  | The cluster infrastructure should be managed as IaC (Infrastructure as Code) specific to your environment. Reference implementation provided in [CloudKube](https://github.com/digihunch/cloudkube) project. Contact [DigiHunch](https://www.digihunch.com/contact/) for professional service to customize the cluster.|

## Toolings

### Helm Chart
The purpose of this repo is to provide a Helm Chart to deploy Orthanc on Kubernetes with a single command, including the creation of self-signed certificates. The Helm Chart is defined in the *[orthanc](https://github.com/digihunch/korthweb/tree/main/orthanc)* directory and is customizable with parameters. The rest of this instruction is based on automatic deployment.
The directory *[manual](https://github.com/digihunch/korthweb/tree/main/manual)* is also kept in this repository to help userstand the deployment and guide development of Helm Chart.

### Istio Service Mesh
Applications running as [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/) requires many common features for observability (e.g. tracing), security (e.g. mTLS), traffic management (e.g. ingress and egress, traffic splitting), and resiliency (circuit breaking, retry/timeout). Service Mesh commodifies these features into a layer between Kubernetes platform and the workload. Istio is a popular choice for Service Mesh. 

### CLI tools
We need these tools to complete installation.
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes.

## Deploy Orthanc using helm
The helm chart is stored in orthanc sub-directory
```sh
helm dependency update orthanc
```
From orthweb directory, run:
```sh
helm install orthweb orthanc --create-namespace --namespace orthweb 
```
To uninstall (and remove persistent volumes for database) 
```sh
helm -n orthweb uninstall orthweb && kubectl -n orthweb delete pvc -l app.kubernetes.io/component=postgresql 
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
```sh
123.22.143.244 dicom.orthweb.com
123.22.143.244 web.orthweb.com
```
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

