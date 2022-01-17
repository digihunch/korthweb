# Deploy Orthanc with GitOps using FluxCD

GitOps is the recommended approach to deploy Orthanc automatically. We use FluxCD as the GitOps tool. This approach also deploys Orthanc workload with two environments (dev and tst). At the end of deployment two instances are deployed, in the dev-orthweb and tst-orthweb namespaces.

To work with this approach, we need a Kubernetes cluster, helm, kubectl and flux, and ensures that local kubectl connects to the cluster.
## Preparation
Fork this repo to your own GitHub account to use as the source of deployment. Then obtain your own Github Token and export it to environment variable GITHUB_TOKEN: 
```sh
export GITHUB_TOKEN=xxx_yyy55555XXXodr7ABBBB234CCccw
```
## Installation

First, we bootstrap the cluster. Suppose the name of your account is *digihunch*, and the repository name is korthweb, the command to run would be:

```sh
flux bootstrap github \
      --owner=digihunch \
      --repository=korthweb \
      --branch=main \
      --personal \
      --path=gitops/fluxcd
```
A deployment key will be created. FluxCD will be install on the cluster, and scans the path specified (gitops/fluxcd) for Kustomization objects.  Kustomization objects defines the sources to sync from. The sync should start automatically (using Kustomization objects) as boostrapping is completed. To check sync progress by kusomization status, run:
```sh
flux get ks --watch
```
For troubleshooting, in the flux-system namespace, check the CRD status. It is also helpful to check the log of Flux:
```sh
flux logs
```
## Validation
The validation steps is the same as with the [manual](https://github.com/digihunch/korthweb/blob/main/manual/README.md#validation) approach in principal. The difference with the GitOps approach, is that there are two namespaces tst-orthweb and dev-orthweb, both of which need to be tested.

To validate the dev workload:
```sh
$ kubectl -n dev-orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
$ keytool -import -alias orthweb.com -file ca.crt -storetype JKS -noprompt -keystore client.truststore -storepass Password123!
$ curl -HHost:web.dev.orthweb.com -v -k -X GET https://web.dev.orthweb.com/app/explorer.html -u orthanc:orthanc --cacert ca.crt
$ storescu -c ORTHANC@dicom.dev.orthweb.com:11112 --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!

To validate the tst workload
$ kubectl -n tst-orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
$ keytool -import -alias orthweb.com -file ca.crt -storetype JKS -noprompt -keystore client.truststore -storepass Password123!
$ curl -HHost:web.tst.orthweb.com -v -k -X GET https://web.tst.orthweb.com/app/explorer.html -u orthanc:orthanc --cacert ca.crt
$ storescu -c ORTHANC@dicom.tst.orthweb.com:11112 --tls12 --tls-aes --trust-store client.truststore --trust-store-pass Password123!
```