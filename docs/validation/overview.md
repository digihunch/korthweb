# Validation

This validation guide is not intended to be an exhaustive list of check points. However, we check both TCP ports service clients with one service. 

## Web traffic
The web service is hosted on port 443. User will need to browse to the URL with a Browser or use `curl` command instead. The traffic is HTTPS by default with a self-signed certificate configured during the deployment process. In addition, users should supply the default username and password (admin:orthanc) when logging on to the web portal. 

## DICOM traffic
The DICOM service is hosted on TCP port 11112. User can verify the port by issuing a C-ECHO DIMSE command to this port, and then send images to the port using C-STORE DIMSE command. DICOM traffic is protected by TLS by default.

## Utilities
The validation steps involves the following tools:

* We still need `kubectl` to examine object in Kubernetes, such as exporting CA information;
* The `curl` tool as HTTP client;
* `openssl` to create client certificate under the same CA with the server;
* `dcmtk` as DICOM client. The dcmtk package includes many executables such as `echoscu` and `storescu`. 

For more details about DICOM testing over TLS, such as the limitation with SNI, Refer to [this](https://www.digihunch.com/2023/02/dicom-testing-with-tls/) post. 
