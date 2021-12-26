
## (Manually) Deploy Orthanc with Istio Ingress

This instruction is tested on Minikube but should work on any K8s cluster. It is based on Istio 1.12.1

### Install Minikube and Istio
```sh
minikube start --memory=12288 --cpus=6 --kubernetes-version=v1.20.2 --nodes 3 --container-runtime=containerd --driver=hyperkit --disk-size=150g
minikube addons enable metallb
minikube addons configure metallb
```
Put in the IP address range for load balancer, for example: 192.168.64.16 - 192.168.64.23. Then install istio using istioctl with the overlay file.

```sh
istioctl install -f overlay.yaml -y --verify
```
The overlay file includes specifications required for this instruction, such as ports. The stdout may report "no Istio installation found" which is not a concern. The Ingress service is running on an IP address in the range specified above, which can be displayed with the following command:
```sh
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
To assist the testing in the rest of the instruction, we can add it to local host file (e.g. /etc/hosts for Mac and Linux), for example:
```
192.168.64.16 web.orthweb.com
192.168.64.16 dicom.orthweb.com
```
On this IP address, we will use port 443 for HTTPS traffic and 11112 for DICOM traffic over TLS. In addition, we also want to install kiali:
```sh
kubectl apply -f istio/samples/addons/prometheus.yaml
kubectl apply -f istio/samples/addons/kiali.yaml
kubectl apply -f istio/samples/addons/jaeger.yaml
kubectl apply -f istio/samples/addons/grafana.yaml
```
To launch kiali from Minikube, run:  
```sh
istioctl dashboard kiali
```
### Configure certificates
Let's generate key and certificate for CA, and use it to sign a certificate for our site.
```sh
openssl req -x509 -sha256 -newkey rsa:4906 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Health Certificate Authority'
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=*.orthweb.com'
openssl x509 -req -sha256 -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
kubectl create -n istio-system secret generic orthweb-cred --from-file=tls.key=server.key --from-file=tls.crt=server.crt --from-file=ca.crt=ca.crt
```
The command above imports key, certificate and CA certificate into istio-system namespace for istio ingress Gateway to use. 

### Deploy application
We start with creating ConfigMaps, which creates the namespace orthweb and label it as requiring sidecar injection. Then we create the Secret needed for applicaiton to communicate with database. We use Helm to deploy the database and two YAML manifests for Deployment and Service to deploy the Orthanc application.
```sh
kubectl apply -f configmap.yaml
kubectl -n orthweb create secret tls tls-orthweb --cert=server.crt --key=server.key
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres-ha bitnami/postgresql-ha \
     --create-namespace --namespace orthweb \
     --set pgpool.tls.enabled=true \
     --set pgpool.tls.certificatesSecret=tls-orthweb \
     --set pgpool.tls.certFilename=tls.crt \
     --set pgpool.tls.certKeyFilename=tls.key \
     --set postgresql.initdbScriptsCM=orthanc-dbinit \
     --set volumePermissions.enabled=true
```
Note that we provide SQL script (stored in orthanc-dbinit entry) to postgresql.initdbScriptsCM instead of pgpool.initdbScriptsCM because the altter doesn't take files with SQL extention, according to the [documentation](https://artifacthub.io/packages/helm/bitnami/postgresql-ha) of PostgreSQL helm chart.
Monitor the service and deploy status until all Pods are up. It usually takes a couple minutes.
```sh
kubectl get all -n orthweb
```
It may take minutes before the PostgreSQL services coming up. Then we bring up application's Deployment and Service.
```sh
kubectl apply -f orthweb-deploy.yaml
kubectl apply -f orthweb-service.yaml
```
The first manifest defines Pods in a Deployment. The Pods contains [readiness probe](https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes) for HTTP health check. The second manifest defines a Kubernetes Service with ClusterIP type,  with 8042 (HTTP) and 4242 (DICOM) ports open. Neither ports are exposed outside of the cluster. We will later need Istio Ingress to expose the services outside of the cluster, as well as to terminate TLS for both HTTP and DICOM.
```sh
kubectl apply -f orthweb-ingress-tls.yaml
```
The command above configures istio ingress with TLS termination. 


### Validation

we use curl to validate HTTPS traffic
```sh
curl -HHost:web.orthweb.com -v -k -X GET https://web.orthweb.com:443/app/explorer.html -u orthanc:orthanc --cacert ca.crt

```
Then we use [dcm4chee](https://github.com/dcm4che/dcm4che/releases) to validate DICOM traffic. Before running C-ECHO, we first import the CA certificate to a trust store, with a password, say Password123!
```sh
keytool -import -alias orthweb -file ca.crt -storetype JKS -keystore client.truststore
storescu -c ORTHANC@dicom.orthweb.com:11112 --tls12 --tls-aes --trust-store path/to/client.truststore --trust-store-pass Password123!
```
We then use storescu (without a DCM file specified) as a C-ECHO SCU. If it returns success, we can C-STORE a DCM file:
```sh
storescu -c ORTHANC@dicom.orthweb.com:11112 TEST.DCM --tls12 --tls-aes --trust-store path/to/client.truststore --trust-store-pass Password123!
```
Once the DICOM file has been sent, and the C-STORE SCP returns success, the image should be viewable from browser. Any [sample](http://www.rubomedical.com/dicom_files/) DICOM image should work for this test case. 

To validate database service, SSH to a workload pod (with some [args](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/) commented out) or a sleeper pod:
```sh
export PGPASSWORD=$DB_PASSWORD && apt update && apt install postgresql postgresql-contrib
psql --host=$DB_ADDR --port $DB_PORT --username=$DB_USERNAME sslmode=require
```

To test Kubernetes Service without Ingress, use port forwarding. 
```sh
kubectl -n orthweb port-forward service/web-svc 8042:8042
curl -k -X GET https://0.0.0.0:8042/app/explorer.html -I -u orthanc:orthanc
```

