
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
192.168.64.16 orthweb.digihunch.com
```
On this IP address, we will use port 443 for HTTPS traffic and 11112 for DICOM traffic over TLS.

### Configure certificates
Let's generate key and certificate for CA, and use it to sign a certificate for our site.
```sh
openssl req -x509 -sha256 -newkey rsa:4906 -keyout ca.key -out ca.crt -days 356 -nodes -subj '/CN=Test Cert Authority'
openssl req -new -newkey rsa:4096 -keyout server.key -out server.csr -nodes -subj '/CN=orthweb.digihunch.com'
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
Monitor the service and deploy status until all Pods are up. It usually takes a couple minutes.
```sh
kubectl get all -n orthweb
```
It may take minutes before the PostgreSQL services coming up. Then we bring up application's Deployment and Service.
```sh
kubectl apply -f orthweb-deploy.yaml
kubectl apply -f orthweb-service.yaml
```
The manifests define a Kubernetes Service with ClusterIP type,  with 8042 (HTTP) and 4242 (DICOM) ports open. Neither ports are exposed outside of the cluster. We will later need Istio Ingress to expose the services outside of the cluster, as well as to terminate TLS for both HTTP and DICOM.
```sh
kubectl apply -f orthweb-ingress-tls.yaml
```
The command above configures istio ingress with TLS termination. 


### Validation

we use curl to validate HTTPS traffic
```sh
curl -HHost:orthweb.digihunch.com -v -k -X GET https://orthweb.digihunch.com:443/app/explorer.html -u orthanc:orthanc --cacert ca.crt

```
Then we use dcm4chee to validate DICOM traffic. Before running C-ECHO, we first import the CA certificate to a trust store, with a password, say Password123!
```sh
keytool -import -alias orthweb -file ca.crt -storetype JKS -keystore client.truststore
storescu -c ORTHANC@orthweb.digihunch.com:11112 --tls12 --tls-aes --trust-store path/to/client.truststore --trust-store-pass Password123!
```
We then use storescu (without a DCM file specified) as a C-ECHO SCU. If it returns success, we can C-STORE a DCM file:
```sh
storescu -c ORTHANC@orthweb.digihunch.com:11112 TEST.DCM --tls12 --tls-aes --trust-store path/to/client.truststore --trust-store-pass Password123!
```
Once the DICOM file has been sent, it should be viewable from browser.
