
# Manual approach

This instruction walks through the steps of manual deployment on an estabished Kubernetes cluster

## Istio and observability add-ons
We use `istioctl` to install istio with the operator manifest in *[istio](https://github.com/digihunch/korthweb/tree/main/manual/istio)* directory:

```sh
istioctl install -f istio/istio-operator.yaml -y --verify
```
Then, we install observability addons and view Kiali dashboard (with istioctl or via port-forwarding):
```sh
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/jaeger.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
istioctl dashboard kiali
kubectl port-forward svc/kiali -n istio-system 8080:20001
```
Kiali may take a few minutes to come up. Here we use a single manifest to deploy Kiali just for demo. For full-blown Kiali deployment, we should use Kiali CRD.

## Configure Certificates
In this step, we generate our own X.509 key and certificate for the site. The certificates and key are stored as secrets and the Istio Ingress will reference them. To install cert manager using Helm:
```sh
helm install cert-manager cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --repo https://charts.jetstack.io --set installCRDs=true
```
Confrim all Pods in cert-manager namespace come up. Then we use cert-manager CRs to create certificate in istio-system namespace, and verify the certificate by decoding the secret object.
```sh
kubectl apply -f certs.yaml
```

## Deploy Orthanc workload

In the `orthweb-cm.yaml` file, we enable peer authentication and label orthweb namespace as requiring Istio sidecar injection. We also declare the config entry for `orthanc.json` and database init script. After that, we use Helm to install PostgreSQL database, which will use the init script.

```sh
kubectl apply -f orthweb-cm.yaml
helm install postgres-ha postgresql-ha \
       --set postgresql.initdbScriptsCM=dbinit \
       --set volumePermissions.enabled=true \
       --set service.portName=tcp-postgresql \
       --repo https://charts.bitnami.com/bitnami \
       --version 11.0.1 \
       --namespace orthweb
kubectl -n orthweb wait deploy/postgres-ha-postgresql-ha-pgpool --for=condition=Available --timeout=10m
kubectl apply -f orthanc.yaml
kubectl -n orthweb get po --watch
```

As a side note, we store the init script db_create.sql as an entry in orthanc-dbinit config map ahead of time before running the Helm chart, because Helm chart parameter [pgpool.initdbScriptsCM](https://artifacthub.io/packages/helm/bitnami/postgresql-ha#initialize-a-fresh-instance) does not take file with .sql extension. The postgres pods takes a few mintues to come all up. After that, we deploy the Orthanc workload as declared in `orthanc.yaml` file.

## Validation and Troubleshooting
First, find out the IP address of istio ingress service:
```sh
kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
On this IP address, we expose port 443 for HTTPS traffic and 11112 for DICOM traffic over TLS. It is important to ensure that both web endpoint (web.orthweb.com) and DICOM endpoint(dicom.orthweb.com) resolve to this IP address. If you do not have control over DNS resolution, consider adding the IP address to host file (e.g. /etc/hosts) on your testing machine, for example:
```
192.168.64.16 web.orthweb.com
192.168.64.16 dicom.orthweb.com
```
We can quickly test the web endpiont by browsing to https://web.orthweb.com:443/app/explorer.html or use curl command:
```sh
kubectl -n istio-system get secret ca-secret -o jsonpath='{.data.tls\.crt}' | base64 -d > ca.crt

curl -HHost:web.orthweb.com -k -X GET https://web.orthweb.com:443/app/explorer.html -u admin:orthanc --cacert ca.crt

```
Note that we take a step to export CA's certificate so we can tell curl to trust the server's certificate issued by the CA.

To examine whether the server certificate is configured correctly on an endpoint, we can use openssl command:

```sh
openssl s_client -showcerts -connect web.orthweb.com:443 -servername web.orthweb.com < /dev/null

openssl s_client -showcerts -connect dicom.orthweb.com:11112 -servername dicom.orthweb.com < /dev/null
```

To validate DICOM endpoint, the client should carry its own certificate. To achieve that, we need to generate a key pair for the client. Then we need to export the CA's key so we can get the CA to sign the certificate of the client

```sh
openssl req -new -newkey rsa:4096 -nodes -subj /C=CA/ST=Ontario/L=Waterloo/O=Digihunch/OU=Imaging/CN=dcmclient.orthweb.digihunch.com/emailAddress=dcmclient@digihunch.com -keyout client.key -out client.csr

kubectl -n istio-system get secret ca-secret -o jsonpath='{.data.tls\.key}' | base64 -d > ca.key

openssl x509 -req -sha256 -days 365 -in client.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out client.crt
```

We can provide the `client.key` and `client.crt` to dcmtk executables.  
Take C-ECHO as an example, we can use the following command:

```sh
echoscu -aet TESTER -aec ORTHANC -d +tls client.key client.crt -rc +cf ca.crt dicom.orthweb.com 11112
```
The result should report success. To C-STORE an image, we can run:
```sh
storescu -aet TESTER -aec ORTHANC -d +tls client.key client.crt -rc +cf ca.crt dicom.orthweb.com 11112 DICOM_CT/COVID/56364504.dcm
``` 
The result should report success with C-STORE with return code 0. From the web portal you should be able to see the image sent.

Sometimes one needs to validate connectivity from orthweb namespace to Postgres database. To do so, connect to Bash terminal of a sleeper pod (or a workload pod with some [args](https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/) commented out), and run:
```sh
$ export PGPASSWORD=$DB_PASSWORD && apt update && apt install postgresql postgresql-contrib
$ psql --host=$DB_ADDR --port $DB_PORT --username=$DB_USERNAME sslmode=require
```
From there you should be able to execute SQL statements.
