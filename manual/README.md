
# Deploy Orthanc the Manual Way

In this instruction, we deploy Orthanc manually. Use this instruction only if you need to troubleshoot or understand the deployment details. Otherwise, for automation, use the *GitOps* or *Helm Chart* [approach](https://github.com/digihunch/korthweb/blob/main/README.md#deployment-approach).

This manual approach uses external Helm Chart for dependencies (Istio, Cert-Manager and PostgreSQL) and applies YAML manifests for the rest of the workload.

## Install Istio and observability add-on
The files used are kept in the *[istio](https://github.com/digihunch/korthweb/tree/main/manual/istio)* directory. We can install istio using Helm chart or using istioctl. We use istioctl because it is more common (as per [official guide](https://istio.io/latest/docs/setup/install/istioctl/#prerequisites)) and it is done in a single command:

```sh
istioctl install -f istio/istio-operator.yaml -y --verify
```
If you prefer to install istio using Helm charts, use the install-using-helm.sh script. Then we can install observability addons and view Kiali dashboard
```sh
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
```
Wait until the Pods are created and we can connect to Kiali dashboard using one of the commands below:
```sh
istioctl dashboard kiali
kubectl port-forward svc/kiali -n istio-system 8080:20001
```
Note this method of installing Kiali is for demo ony. 

## Configure certificates
In this step, we generate our own X.509 key and certificate for ingress. We start by installing cert manager.
```sh
helm install cert-manager cert-manager --namespace cert-manager --create-namespace --version v1.7.1 --repo https://charts.jetstack.io --set installCRDs=true
```
Confrim all Pods in cert-manager namespace come up. Then we use cert-manager resources to create what we need in the orthweb namespace. The manifests are in certs directory.
```sh
kubectl apply -f certs/ca.yaml
kubectl apply -f certs/site.yaml
```
Now we can verify the certificate created in istio-system namespace by decoding the secret. We'll also store the encoded certificate to a file and convert it to a Java trust store for later use.
```sh
openssl x509 -in <(kubectl -n istio-system get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 -d) -text -noout 
kubectl -n istio-system get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt
keytool -import -alias orthweb.com -file ca.crt -storetype JKS -noprompt -keystore client.truststore -storepass Password123!
```
The Gateway resource will reference the secret created above.  
## Deploy workload
We start by labeling orthweb namespace as requiring sidecar injection. Then we create the ConfigMap and Secret needed for applicaiton to communicate with database. We use Helm to deploy the database and two YAML manifests for Deployment and Service to deploy the Orthanc application.
```sh
kubectl apply -f orthweb-cm.yaml
helm install postgres-ha postgresql-ha \
       --set postgresql.initdbScriptsCM=dbinit \
       --set volumePermissions.enabled=true \
       --set service.portName=tcp-postgresql \
       --repo https://charts.bitnami.com/bitnami \
       --namespace orthweb
kubectl -n orthweb wait deploy/postgres-ha-postgresql-ha-pgpool --for=condition=Available
kubectl apply -f orthweb-workload.yaml
kubectl -n orthweb get po --watch
kubectl apply -f orthweb-ingress-tls.yaml
```
As a side note, I had to implement a trick here. Since Helm chart parameter [pgpool.initdbScriptsCM](https://artifacthub.io/packages/helm/bitnami/postgresql-ha#initialize-a-fresh-instance) does not take file with .sql extension. We store the init script db_create.sql as an entry in orthanc-dbinit config map ahead of time before running the Helm chart.

The Orthanc Pods contains [readiness probe](https://stackoverflow.com/questions/33484942/how-to-use-basic-authentication-in-a-http-liveness-probe-in-kubernetes) for HTTP health check. A ClusterIP service exposes port 4242 for DICOM traffic, and 8042 for HTTP traffic. The last command installs istio virtual service and gateways for HTTP and DICOM traffic in orthweb-ingress-tls.yaml

## Validation and Troubleshooting
We need to find out the IP address of istio ingress service:
```sh
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
On this IP address, port 443 expects HTTPS traffic and 11112 expects DICOM traffic over TLS. To assist with the rest of validation steps, it is convenient to add the IP address to local host file (e.g. /etc/hosts for Mac and Linux), for example:
```
192.168.64.16 web.orthweb.com
192.168.64.16 dicom.orthweb.com
```
Then we can use the certificate file (exported previously when creating certificates) and trust store file created in previous steps to validate the site. We use curl to validate HTTPS traffic and storescu, a tool in [dcm4chee](https://github.com/dcm4che/dcm4che/releases) to verify DICOM connectivity with C-ECHO.
```sh
curl -HHost:web.orthweb.com -k -X GET https://web.orthweb.com:443/app/explorer.html -u orthanc:orthanc --cacert ca.crt
storescu -c ORTHANC@dicom.orthweb.com:11112 --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```
The curl response should return the full web page. The storescu response should say Received Echo Response (Success). If it does, we can further test using storescu again to send a DCM file to orthweb dicom service. Any [sample](http://www.rubomedical.com/dicom_files/) DICOM image should work for this test case. The command looks like this:
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
