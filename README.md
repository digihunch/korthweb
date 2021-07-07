# Korthweb
Korthweb is a web deployment of Orthanc on Kubernetes (based on AWS EKS)

To deploy this solution, the client and server must have some tools installed:
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html): we need to install and configure awscli to manage resources in AWS. The credentials for programatic access is stored under profile. Instruction is [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html). Note that we do not directly interact with awscli. The eksctl tool will use its configuration.
* [eksctl](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html): build EKS cluster. It uses a template file, and connect with awscli profile to produce a CloudFormation template to create resources required for EKS cluster.
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): interact with kubernetes cluster using specified context. Once EKS cluster is up, we need to update the context of kubectl so it connect to the EKS cluster correctly.
* [openssl](https://www.openssl.org/): if you do not have an existing key and certificate, and you need to create self-signed ones. Use OpenSSL, which is usually installed by default on MacOS or Linux.
* [helm](https://helm.sh/docs/intro/install/): To install postgres database, we leverage existing package (helm chart) to deploy database from a single command.  

## Build EKS cluster
We use eksctl with a template to create EKS cluster, then update kubectl configuration pointing to the cluster. The template cluster.yaml is located in eks directory.
```sh
eksctl create cluster -f cluster.yaml --profile default
aws eks update-kubeconfig --name orthweb-cluster --profile default --region us-east-1 
```
The cluster provisioning at this step may take as long as 20 minutes. 


## Load configuration
Once K8s cluster is configured, we load application configuration. 
If we don't already have key and certificates, let's generate key and certificate for CA, and use it to sign a certificate for our site.
```sh
openssl req -x509 -sha256 -newkey rsa:4906 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Test Cert Authority'
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=orthweb.digihunch.com'
openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
```
Create configmap and import the certificate and key as secret
```sh
kubectl apply -f configmap.yaml
kubectl -n orthweb create secret tls tls-orthweb --cert=server.crt --key=server.key
```

## Deploy Database
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

## Deploy Application
```sh
kubectl apply -f web-deploy.yaml
kubectl apply -f web-service.yaml
```
The last command brings up a network load balancer, with 8042 (HTTPS) and 4242 (DICOM TLS) ports open. The web-svc status has loadBalancer field under status, which indicates the dns name of load balancer. The DNS name may take a couple minutes to become resolvable. The IP address can be added to local host file (e.g. /etc/hosts for Mac and Linux) like this:
```
3.232.159.192 orthweb.digihunch.com 
```
The load balancer may take a couple minutes to come up.

## Validation of deployment
we use curl and echoscu (installed as dcmtk brew package) to validate. Assuming the DNS resolution is working (either by editing /etc/hosts locally or, by adding an A record in DNS)
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

## Clean up
Use eksctl again to delete cluster so it stops incurring charges.
```sh
eksctl delete cluster -f cluster.yaml --profile default
```
The deletion takes a couple minutes.

## Troubleshooting Tips
If Pod does not come to Running status, and is stuck with CreateContainerConfigError, check Pod status details with -o yaml. Consider configuration error such as passing secret data to env variable. 
```sh
kubectl -n orthweb get po web-dpl-6ddb587885-wj4cx -o yaml
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

## Notes
1. How container [args](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/) work:

2. How http authentication works in readiness [probe](https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes).

3. Postgres Container Documentation (postgresql.initdbScriptsCM takes files with sql extension, while pgpool.initdbScriptsCM doesn't, according to [this](https://artifacthub.io/packages/helm/bitnami/postgresql-ha)
