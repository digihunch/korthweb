
## (Manually) Deploy Orthanc with Istio Ingress

This instruction is tested on Minikube but should work on any K8s cluster. It is based on Istio 1.12.1

### Install Minikube and Istio

#### Install Minikube
```sh
minikube start --memory=12288 --cpus=6 --kubernetes-version=v1.20.2 --nodes 3 --container-runtime=containerd --driver=hyperkit --disk-size=150g
minikube addons enable metallb
minikube addons configure metallb
```
There are two approaches provided to install Istio. Files required in both approaches are located in the *[istio](https://github.com/digihunch/korthweb/tree/main/manual/istio)* directory. Choose one of the approaches below to complete istio installation.

#### Approach 1. Install Istio using Overlay file
Put in the IP address range for load balancer, for example: 192.168.64.16 - 192.168.64.23. Then install istio using istioctl with the overlay file.

```sh
istioctl install -f overlay.yaml -y --verify
```
The overlay file includes specifications required for this instruction, such as ports. The stdout may report "no Istio installation found" which is not a concern. 

#### Approach 2. Install Istio using Helm Chart
There are a number of Helm [Charts](https://artifacthub.io/packages/search?org=istio) for Istio components and they can be added to repo list:
```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```
Then we install components in the following sequence:
```sh
# use base chart to install crds, then verify with "kubectl get crds"
helm install -n istio-system istio-base istio/base --create-namespace
# use istiod chart to install istiod
helm -n istio-system install istiod istio/istiod -f istiod-values.yaml --wait
# use gateway chart to install ingress gateway
helm -n istio-system install istio-ingress istio/gateway -f ingress-gateway-values.yaml
# use gateway chart to install egress gateway
helm -n istio-system install istio-egress istio/gateway -f egress-gateway-values.yaml
```
#### Configure DNS and addons
The Ingress service is running on an IP address in the range specified above, which can be displayed with the following command:
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
In this step, we generate key and certificate for ingress. We start by installing cert manager.
```sh
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.0.3 --set installCRDs=true
```
Then we create key, certificate and CA certificate into secrets for istio ingress Gateway to consume. The secret and the gateway service must be in the same namespace. Create Secret with this command: 
```sh
kubectl apply -f certs/ca.yaml
kubectl apply -f certs/site.yaml
```
A secret named orthweb-secret is created in namespace istio-system. To view the certificate, parse and decode the secret:
```sh
openssl x509 -in <(kubectl -n istio-system get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 -d) -text -noout
```

### Deploy application
We start with creating ConfigMaps, which creates the namespace orthweb and label it as requiring sidecar injection. Then we create the Secret needed for applicaiton to communicate with database. We use Helm to deploy the database and two YAML manifests for Deployment and Service to deploy the Orthanc application.
```sh
kubectl apply -f orthweb-cm.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgres-ha bitnami/postgresql-ha \
     --namespace orthweb \
     --set postgresql.initdbScriptsCM=dbinit \
     --set volumePermissions.enabled=true
```
Note that we provide SQL script (stored in orthanc-dbinit entry) to postgresql.initdbScriptsCM instead of pgpool.initdbScriptsCM because the altter doesn't take files with SQL extention, according to the [documentation](https://artifacthub.io/packages/helm/bitnami/postgresql-ha) of PostgreSQL helm chart.
Monitor the service and deploy status until all Pods are up. It usually takes a couple minutes.
```sh
kubectl get all -n orthweb
```
It may take minutes before the PostgreSQL services coming up. Then we bring up application's Deployment and Service.
```sh
kubectl apply -f orthweb-workload.yaml
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

