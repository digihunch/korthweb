# Deploy Orthanc as Helm Chart
In this directory, we build a Helm Chart called orthanc. The content of the Chart is stored in the *orthanc* directory. Currently, this chart is not released. Therefore, users need to clone this repo first and enter the helm sub-directory.
```sh
git clone git@github.com:digihunch/korthweb.git
cd korthweb/helm
```
The chart is stored as the sub-directory named *orthanc*. We can update dependency and then install the chart:
```sh
helm dependency update orthanc
helm install orthweb orthanc --create-namespace --namespace orthweb 
```
Once installation is completed, check Pod status in the orthweb namespace. To uninstall (and remove persistent volumes for database) 
```sh
helm -n orthweb uninstall orthweb && kubectl -n orthweb delete pvc -l app.kubernetes.io/component=postgresql 
```
## Validation
The helm chart by default does a lot of automation, including the creation of certificates for the following three domain name. The helm chart also creates a clusterIP service, and an ingress for HTTP and DICOM traffic. 

1. To find out on which IP the services are exposed, run the following command and get the External IP of the service with Load Balancer Type:
```sh
kubectl -n orthweb get svc
```
Suppose the External IP is 192.168.64.16, we need to ensure the following DNS names resolves to this IP address:
* dicom.orthweb.com
* web.orthweb.com

We can edit /etc/host file to force resolution. The bottom of /etc/hosts will look like this:
```sh
192.168.64.16 dicom.orthweb.com
192.168.64.16 web.orthweb.com
```

2. Test the port from the test client (e.g. MacBook or PC). Both should report succeed.
```sh
nc -vz dicom.orthweb.com 4242
nc -vz web.orthweb.com 8042
```

3. Export the CA certificate (which should be the same for dicom and web), and then import it into a Java trust store for DICOM testing with dcm4che. When creating a trust store, a password needs to be provided and suppose our password is Password123!
```sh
kubectl -n orthweb get secret dicom.orthweb.com -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
keytool -import -alias orthweb.com -file ca.crt -storetype JKS -noprompt -keystore client.truststore -storepass Password123!
```

4. To test web connection, simply browse to https://web.orthweb.com/app/explorer.html from browser and use default username and password. Alternatively, use curl command to ensure 200 code is returned:
```sh
curl -HHost:web.orthweb.com -v -k -X GET https://web.orthweb.com:443/app/explorer.html -u orthanc:orthanc --cacert ca.crt
```

7. Validate DICOM connectivity using dcm4che's storescu tool, for C-ECHO:
```sh
./storescu -c ORTHANC@dicom.orthweb.com:11112 --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```
The response should say Received Echo Response (Success).

8. Validate DICOM C-store by sending a DICOM image. We can use the same storescu command with an extra parameter for the image:
```sh
./storescu -c ORTHANC@dicom.orthweb.com:11112 ~/Downloads/0002.DCM --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```
The response should say Received Store Response (Success) and the study should be viewable from Orthanc web portal.
