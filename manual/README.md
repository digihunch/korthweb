
# Deploy Orthanc the Manual Way

In this instruction, we deploy Orthanc manually. Use this instruction only if you need to troubleshoot or understand the deployment details. Otherwise, for automation, use the *GitOps* or *Helm Chart* [approach](https://github.com/digihunch/korthweb/blob/main/README.md#deployment-approach).

This manual approach uses external Helm Chart for dependencies (Istio, Cert-Manager and PostgreSQL) and applies YAML manifests for the rest of the workload.

## Install Istio

There are two methods to install Istio, using the files in the *[istio](https://github.com/digihunch/korthweb/tree/main/manual/istio)* directory. 
### Method 1. Using istioctl with IstioOperatorAPI file
We use istioctl command-line tool (following [official guide](https://istio.io/latest/docs/setup/install/istioctl/#prerequisites)) with the provided overlay file for our customization: 
```sh
istioctl install -f istio/istio-operator.yaml -y --verify
```
The stdout at the end of installation may report "no Istio installation found" which is not a concern. 
### Method 2. Using Helm Chart
Since Nov 2021, Istio has released offical Helm [Charts](https://artifacthub.io/packages/search?org=istio) for different Istio components. The Helm Repo should be registered first:
```sh
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kiali https://kiali.org/helm-charts
helm repo update
```
Then in the following order, we create namespaces and install required Isto components:
```sh
kubectl create ns istio-system
kubectl create ns orthweb
# use base chart to install crds, then verify with "kubectl get crds"
helm install -n istio-system istio-base istio/base
# use istiod chart to install istiod
helm -n istio-system install istiod istio/istiod -f istio/istiod-values.yaml --wait
# use gateway chart to install ingress gateway
helm -n orthweb install istio-ingress istio/gateway -f istio/ingress-gateway-values.yaml
# use gateway chart to install egress gateway
helm -n orthweb install istio-egress istio/gateway -f istio/egress-gateway-values.yaml
```
To install observability addons (prometheus, grafana and kiali)
```sh
helm install prom prometheus-community/kube-prometheus-stack --version 34.1.1 -n monitoring -f monitoring/prom-values.yaml --create-namespace

kubectl apply -f monitoring/service-monitor-cp.yaml
kubectl apply -f monitoring/pod-monitor-dp.yaml

kubectl -n monitoring create cm istio-dashboards \
--from-file=pilot-dashboard.json=monitoring/dashboards/pilot-dashboard.json \
--from-file=istio-workload-dashboard.json=monitoring/dashboards/istio-workload-dashboard.json \
--from-file=istio-service-dashboard.json=monitoring/dashboards/istio-service-dashboard.json \
--from-file=istio-performance-dashboard.json=monitoring/dashboards/istio-performance-dashboard.json \
--from-file=istio-mesh-dashboard.json=monitoring/dashboards/istio-mesh-dashboard.json \
--from-file=istio-extension-dashboard.json=monitoring/dashboards/istio-extension-dashboard.json

kubectl label -n monitoring cm istio-dashboards grafana_dashboard=1

helm install --namespace operator kiali-operator  kiali/kiali-operator --create-namespace -f monitoring/kiali-value.yaml
```
To launch Kiali from command terminal, run:  
```sh
$ kubectl port-forward svc/kiali -n monitoring 8080:20001
```

## Configure certificates
In this step, we generate key and certificate for ingress. We start by installing cert manager.
```sh
$ helm repo add jetstack https://charts.jetstack.io
$ helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.0.3 --set installCRDs=true
```
Then we create key, certificate and CA certificate into secrets for istio ingress Gateway to consume. The secret and the gateway service must be in the same namespace. Create Secret with this command: 
```sh
$ kubectl apply -f certs/ca.yaml
$ kubectl apply -f certs/site.yaml
```
A secret named orthweb-secret is created in namespace istio-system. To view the certificate and export it, parse and decode the secret:
```sh
$ openssl x509 -in <(kubectl -n orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 -d) -text -noout
```
The Ingress Gateway will use the secret stored as Kubernetes secret. We can export the secret to file for the validation steps below.
## Deploy workload
We start by labeling orthweb namespace as requiring sidecar injection. Then we create the ConfigMap and Secret needed for applicaiton to communicate with database. We use Helm to deploy the database and two YAML manifests for Deployment and Service to deploy the Orthanc application.
```sh
$ kubectl apply -f orthweb-cm.yaml
$ helm repo add bitnami https://charts.bitnami.com/bitnami
$ helm install postgres-ha bitnami/postgresql-ha \
       --namespace orthweb \
       --set postgresql.initdbScriptsCM=dbinit \
       --set volumePermissions.enabled=true \ 
       --set service.portName=tcp-postgresql
$ kubectl apply -f orthweb-workload.yaml
```
Note that we provide SQL script (stored in orthanc-dbinit entry) to postgresql.initdbScriptsCM instead of pgpool.initdbScriptsCM because the latter doesn't take files with SQL extention, according to the [documentation](https://artifacthub.io/packages/helm/bitnami/postgresql-ha) for PostgreSQL helm chart.
Monitor the service and deploy status until all Pods are up, which takes a minutes.
```sh
$ kubectl -n orthweb get all
```

The Orthanc Pods contains [readiness probe](https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes) for HTTP health check. A ClusterIP service exposes port 4242 for DICOM traffic, and 8042 for HTTP traffic. The Istio Ingress exposes the service outside of the cluster, as well as to terminates TLS for both HTTP and DICOM. To install the Istio Ingress Gateways:
```sh
$ kubectl apply -f orthweb-ingress-tls.yaml
```
Now installation is completed.

## Validation
We need to find out the IP address of istio ingress service:
```sh
$ kubectl -n orthweb get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
On this IP address, port 443 expects HTTPS traffic and 11112 expects DICOM traffic over TLS. To assist with the rest of validation steps, it is convenient to add the IP address to local host file (e.g. /etc/hosts for Mac and Linux), for example:
```
192.168.64.16 web.orthweb.com
192.168.64.16 dicom.orthweb.com
```
Then we can use the certificate file and trust store file created in previous steps to validate the site. We use curl to validate HTTPS traffic:
```sh
$ kubectl -n orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
$ curl -HHost:web.orthweb.com -v -k -X GET https://web.orthweb.com:443/app/explorer.html -u orthanc:orthanc --cacert ca.crt

```
Then we use [dcm4chee](https://github.com/dcm4che/dcm4che/releases) to validate DICOM traffic. Before running C-ECHO, we first import the CA certificate to a trust store, with a password, say Password123!
```sh
$ kubectl -n orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
$ keytool -import -alias orthweb.com -file ca.crt -storetype JKS -noprompt -keystore client.truststore -storepass Password123!
$ storescu -c ORTHANC@dicom.orthweb.com:11112 --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```
We then use storescu (without a DCM file specified) as a C-ECHO client to test for success response:
```sh
$ storescu -c ORTHANC@dicom.orthweb.com:11112 --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```
The response should say Received Echo Response (Success). If it does, we can C-STORE a DCM file using storescu again, with a DCM file provided. Any [sample](http://www.rubomedical.com/dicom_files/) DICOM image should work for this test case. The command looks like:
```sh
$ storescu -c ORTHANC@dicom.orthweb.com:11112 TEST.DCM --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```
Once the DICOM file has been sent, and the C-STORE SCP returns success, the image should be viewable from browser. 

If you see the image, it validates application connectivity to database. If there seems to be database connectivity issue, to take a closer look, connect to Bash terminal of a sleeper pod (or a workload pod with some [args](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/) commented out), and run:
```sh
$ export PGPASSWORD=$DB_PASSWORD && apt update && apt install postgresql postgresql-contrib
$ psql --host=$DB_ADDR --port $DB_PORT --username=$DB_USERNAME sslmode=require
```
From there you should be able to execute SQL statements.
