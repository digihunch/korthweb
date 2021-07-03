# Korthweb

Korthweb is a web deployment of Orthanc on Kubernetes (based on AWS EKS)

To deploy this solution, the client and server must have some tools installed:
* awscli: interact with AWS
* eksctl: build EKS cluster
* kubectl
* openssl: only if key and certificate need to be created
* helm: install kubernetes service

## Build EKS cluster
```sh
eksctl create cluster --profile personal \
    --name mytest \
    --region=us-east-1 \
    --tags environment=tesing \
    --nodes=3 \
    --version=1.21 \
    --ssh-access \
    --ssh-public-key=~/.ssh/id_rsa.pub \
    --kubeconfig=./kubeconfig.mtest.yaml

eksctl create cluster -f cluster.yaml --profile personal
aws eks update-kubeconfig --name basic-cluster
```
## Prepare Certificate
Generate CA key and cert
```sh
openssl req -x509 -sha256 -newkey rsa:4906 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Test Cert Authority'
```
Generate server key and cert
```sh
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=orthweb.digihunch.com'
openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
```
Now import the certificate and key as secret
```sh
kubectl -n orthweb create secret tls tls-orthweb --cert=server.crt --key=server.key
kubectl -n nginx-ingress create secret tls default-server-secret --cert=server.crt --key=server.key
```

## Deploy Database
The initial install of database will require an initialization script which is stored in config map. Create config map from configmap.yaml
```sh
kubectl apply -f configmap.yaml
```
We use helm chart provided by Bitnami to install Postgres. If the helm repo has not been added, add it.
```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
```
Initialize postgres database in HA, with custom options as below:
```sh
helm install postgres-ha bitnami/postgresql-ha \
     --create-namespace --namespace orthweb \
     --set pgpool.tls.enabled=true \
     --set pgpool.tls.certificatesSecret=tls-orthweb \
     --set pgpool.tls.certFilename=tls.crt \
     --set pgpool.tls.certKeyFilename=tls.key \
     --set postgresql.initdbScriptsCM=orthanc-dbinit
```
Monitor the service and deploy status untill all is up:
```sh
kubectl get all -n orthweb
```

## Deploy Application
```sh
kubectl apply -f web-deploy.yaml
kubectl apply -f web-service.yaml
```
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
curl -X GET 0.0.0.0:8042/app/explorer.html -I -u orthanc:orthanc
```

SSL termination
https://stackoverflow.com/questions/65857360/kubernetes-ingress-tcp-service-ssl-termination

## Notes
1. How container args work:
https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/

2. How http authentication works in readinessprobe
https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes

3. Postgres Container Documentation (postgresql.initdbScriptsCM takes files with sql extension, while pgpool.initdbScriptsCM doesn't. According to: https://artifacthub.io/packages/helm/bitnami/postgresql-ha
