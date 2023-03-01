# Validation after GitOps approach

## Validation
The validation steps is the same as with the [manual](https://github.com/digihunch/korthweb/blob/main/manual/README.md#validation) approach in principal. The difference with the GitOps approach, is that there are two namespaces mhr-orthweb and bhs-orthweb, both of which need to be tested.

Eitherway, make sure DNS resolution works. If you're testing using Minikube locally, you may mock DNS resolution to ingress IP by adding the followings to /etc/hosts:
```sh
192.168.64.16 web.bhs.orthweb.com
192.168.64.16 dicom.bhs.orthweb.com
192.168.64.17 web.mhr.orthweb.com
192.168.64.17 dicom.mhr.orthweb.com
```

Take bhs facility as an example, the validation steps are as follows:
```sh
# bhs: generate client key pair
openssl req -new -newkey rsa:4096 -nodes -subj /C=CA/ST=Ontario/L=Waterloo/O=Digihunch/OU=Imaging/CN=dcmclient.bhs.orthweb.com/emailAddress=dcmclient@digihunch.com -keyout bhs.client.key -out bhs.client.csr

# bhs: export intermediate CA credentials
kubectl -n bhs-orthweb get secret int-ca-secret -o jsonpath='{.data.tls\.key}' | base64 -d > bhs.int.ca.key
kubectl -n bhs-orthweb get secret int-ca-secret -o jsonpath='{.data.tls\.crt}' | base64 -d > bhs.int.ca.crt

# bhs: get intermediate CA to sign client cert 
openssl x509 -req -sha256 -days 365 -in bhs.client.csr -CA bhs.int.ca.crt -CAkey bhs.int.ca.key -set_serial 01 -out bhs.client.crt

# bhs: validate web request (without client certificate)
curl -HHost:web.bhs.orthweb.com -k -X GET https://web.bhs.orthweb.com:443/app/explorer.html -u admin:orthanc --cacert bhs.int.ca.crt

# bhs: validate DICOM c-echo request (with client certificate)
echoscu -aet TESTER -aec ORTHANC -d +tls bhs.client.key bhs.client.crt -rc +cf bhs.int.ca.crt dicom.bhs.orthweb.com 11112

# bhs: validate DICOM c-store request (with client certificate)
storescu -aet TESTER -aec ORTHANC -d +tls bhs.client.key bhs.client.crt -rc +cf bhs.int.ca.crt dicom.bhs.orthweb.com 11112 DICOM_CT/0001.dcm
```

To check Pod logs, use Kiali. We can use port-forward to expose kiali service.
```sh
kubectl port-forward svc/kiali -n monitoring 8080:20001
```