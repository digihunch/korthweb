# Deploy Orthanc as Helm Chart
In this approach, we deploy Orthanc with a single command, using the purpose-built Orthanc Helm Chart stored in the *orthanc* sub-directory. This chart is not released in a public Helm Repository. The content is simply stored in the local sub-directory. In order to deploy, we need to clone this repo first and enter the helm directory. Then we update dependency and install the chart:
```sh
$ git clone git@github.com:digihunch/korthweb.git
$ cd korthweb/helm
$ helm dependency update orthanc
$ helm install orthweb orthanc --create-namespace --namespace orthweb 
```
The installation is completed and you can monitor the pod status in the target namespace. 
If you need to uninstall it and remove persistent data, simply run:
```sh
helm -n orthweb uninstall orthweb && kubectl -n orthweb delete pvc -l app.kubernetes.io/component=postgresql 
```
Then the uninstallation is done.
## Validation
The *orthanc* Helm Chart automates a lot of activities, including the creation of certificates for the three FQDNs, installation of PostgreSQL using dependency chart, configuring the orthanc workload, and setting up an ingress for HTTP and DICOM traffic. 

Validation steps of the Helm approach is nearly identical to that of the [manual](https://github.com/digihunch/korthweb/tree/main/manual#validation) approach, except that the TLS secret name may be different. In this approach, the secret names are web.orthweb.com and dicom.orthweb.com.