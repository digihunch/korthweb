# Deploy Orthanc with GitOps using FluxCD

GitOps is the recommended approach to deploy Orthanc automatically. We use FluxCD as the GitOps tool.

## Prerequisite
1. Have a Kubernetes cluster with Load Balancer (e.g. Minikube with MetalLB) 
2. Install helm, kubectl, and flux locally, and ensure that kubectl connects to the target Kubernetes cluster.
3. Fork this repo to your own GitHub account. Suppose the name of your account is *digihunch*, and the repository name is korthweb
4. Obtain your own Github Token and export it to environment variable GITHUB_TOKEN: 
```sh
export GITHUB_TOKEN=xxx_yyy55555XXXodr7ABBBB234CCccw
```
## Installation
The first step during installation is to bootstrap the cluster. In this step, Flux is installed on the target cluster, it also creates a directory (if not exist) in the repo, as indicated in the path argument.

```sh
flux bootstrap github \
    --owner=digihunch \
    --repository=korthweb \
    --branch=main \
    --personal \
    --path=gitops/environment/dev
```
A deployment key will be created as the bootstrapping is completed. The sync should start automatically as boostrapping is completed.

To check sync status, run:
```sh
flux get kustomizations
```
For troubleshooting, in the flux-system namespace, check the CRD status.

## Validation
Check out the [validation](https://github.com/digihunch/korthweb/blob/main/manual/README.md#validation) section for [manual](https://github.com/digihunch/korthweb/blob/main/manual/README.md) install. 