## Validation and Troubleshooting - manual
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