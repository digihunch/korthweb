# orthkube
orthweb on kubernetes

1. Prerequisite
* eksctl
* kubectl
* helm
* openssl or cfssl
Generate CA key and cert
```sh
openssl req -x509 -sha256 -newkey rsa:4906 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Test Cert Authority'
```
Generate server key and cert
```sh
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=orthweb.digihunch.com' && openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
```
2. Create Kubernetes Cluster 
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
3. Install dependency
Generate and import certificate and key

Generate key and self-signed certificate using OpenSSL (interactive)
```sh
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ca-key.pem -out ca.pem
```

Geneerate key and self-signed certificate using CFSSL with existing configuration:
```sh
cfssl gencert -initca site.json | cfssljson -bare ca
```

import as secrets
```sh
kubectl -n orthweb create secret tls tls-orthweb --cert=ca.pem --key=ca-key.pem
```

4. Install orthanc
```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres-ha bitnami/postgresql-ha \
     --create-namespace --namespace orthweb \
     --set pgpool.tls.enabled=true \
     --set pgpool.tls.certificatesSecret=tls-orthweb \
     --set pgpool.tls.certFilename=tls.crt \
     --set pgpool.tls.certKeyFilename=tls.key \
     --set postgresql.initdbScriptsCM=orthanc-dbinit
kubectl get all -n orthweb
```
To add username to secrets and then validate
```sh
kubectl -n orthweb create secret generic postgres-ha-postgresql-ha-postgresql --from-literal=postgresql-username=postgres --dry-run -o yaml | kubectl apply -f -
# kubectl get secret --namespace orthweb postgres-ha-postgresql-ha-postgresql -o jsonpath="{.data.postgresql-username}" | base64 --decode
```

When Pod dies for unknown reason, check postgres connectivity from within the Pod:
```sh
export PGPASSWORD=$DB_PASSWORD && apt update && apt install postgresql postgresql-contrib
psql --host=$DB_ADDR --port $DB_PORT --username=$DB_USERNAME sslmode=require
```
CreateContainerConfigError:
consider configuration error such as passing secret data to env variable.

SSL termination
https://stackoverflow.com/questions/65857360/kubernetes-ingress-tcp-service-ssl-termination
Postgres Container Documentation (postgresql.initdbScriptsCM takes *.sql while pgpool.initdbScriptsCM doesn't
https://artifacthub.io/packages/helm/bitnami/postgresql-ha


5. Test

```sh
kubectl -n orthweb port-forward service/web-svc 8042:8042
curl -X GET 0.0.0.0:8042/app/explorer.html -I -u orthanc:orthanc
```


Note:
1. How container args work:
https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/

2. How http authentication works in readinessprobe
https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes
