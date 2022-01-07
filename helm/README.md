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
The helm chart by default does a lot of automation, including the creation of certificates for the following three domain name. The helm chart also creates a public facing load balancer. we need to collect some information before validation.
db.orthweb.com
dcm.orthweb.com
web.orthweb.com

The second and third DNS names are external facing. To validate the site, we apply a trick to artificially point the DNS name to the public IP address of load balancer.

1. Find out the DNS address of load balancer
```sh
kubectl get svc 
``` 
Jot down the EXTERNAL-IP of orthweb-orthanc.  Suppose we get xyz.elb.us-east-1.amazonaws.com

2. find out the public IP of load balancer by dns name
```sh
nslookup xyz.elb.us-east-1.amazonaws.com
```
Jot down the IP address. Suppose we get 123.22.143.244

3. Edit the host file of your client laptop, add the line below to the bottom of /etc/hosts
```sh
123.22.143.244 dicom.orthweb.com
123.22.143.244 web.orthweb.com
```
with the steps above, we're making sure dicom.orthweb.com resolves to the correct public IP (effective on the testing client)

4. Test the port from the test client
```sh
nc -vz dicom.orthweb.com 4242
nc -vz web.orthweb.com 8042
```
Both should report succeeded.

5. From kubernetes secret store, pull out the certificate for dicom.orthweb.com into a file for later use
```sh
kubectl get secret dcm.orthweb.com -o jsonpath='{.data}' | jq -r '."ca.crt"' | base64 --decode > dcm.orthweb.com.ca.crt
```

6. To test web connection, simply browse to https://web.orthweb.com:8042/app/explorer.html from browser and use default username and password. Alternatively, use curl command to ensure 200 code is returned:
```sh
curl -k -X GET https://web.orthweb.com:8042/app/explorer.html -I -u orthanc:orthanc
```

7. Validate DICOm connectivity. We need to install dcmtk (use home brew to install) and tell echoscu to present the cert that we just generated above.
```sh
echoscu -v dicom.orthweb.com 4242 --anonymous-tls +cf dcm.orthweb.com.ca.crt
```
The response should say Received Echo Response (Success)

8. Send DICOM image
```sh
storescu -v -aec ORTHANC --anonymous-tls +cf dcm.orthweb.com.ca.crt web.orthweb.com 4242 ~/Downloads/CR.dcm
```
The response should say Received Store Response (Success) and the study should be accessible from Orthanc web portal.
