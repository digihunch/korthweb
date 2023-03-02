

## Validation

Validation steps are nearly identical to those in the [manual](https://github.com/digihunch/korthweb/tree/main/manual#validation) approach, except that the TLS secret name may be different. First, find out the external IP address for traefik ingress:
```sh
kubectl -n orthweb get service orthweb-traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
Ensure that the DNS names web.orthweb.com and dicom.orthweb.com resolve to the external IP address of the traefik service. 

To validate web service:
```sh
kubectl -n orthweb get secret web.orthweb.com -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.crt

curl -HHost:web.orthweb.com -v -k -X GET https://web.orthweb.com:443/app/explorer.html -u admin:orthanc --cacert ca.crt
```
You should see HTML content of the website. 

The steps to validate DICOM traffic is similiar to other deployment option. However, it is currently limited because dcmtk utility does not send SNI in the TLS negotiation.

I was able to test C-ECHO and C-STORE on annonymous tls (+tla) without client certificate.

```sh
echoscu -aet TESTER -aec ORTHANC -d +tla -ic dicom.orthweb.com 11112
storescu -aet TESTER -aec ORTHANC -d +tla -ic dicom.orthweb.com 11112 DICOM_CT/123.dcm
```
