# Korthweb - Orthanc deployment on Kubernetes
Korthweb is an open-source project to deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes platform. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb uses Helm for automation, and Istio for ingress and observability. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc in AWS. 

## Prerequisite


## Toolings

### Helm Chart
The purpose of this repo is to provide a Helm Chart to deploy Orthanc on Kubernetes with a single command, including the creation of self-signed certificates. The Helm Chart is defined in the *[orthanc](https://github.com/digihunch/korthweb/tree/main/orthanc)* directory and is customizable with parameters. The rest of this instruction is based on automatic deployment.
The directory *[manual](https://github.com/digihunch/korthweb/tree/main/manual)* is also kept in this repository to help userstand the deployment and guide development of Helm Chart.
*Note*: currently, the automatic deployment doesn't support Istio because of some limitation with Helm. See [readme](https://github.com/digihunch/korthweb/blob/main/istio/README.md).

### Istio Service Mesh
Applications running as [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/) requires many common features for observability (e.g. tracing), security (e.g. mTLS), traffic management (e.g. ingress and egress, traffic splitting), and resiliency (circuit breaking, retry/timeout). Service Mesh commodifies these features into a layer between Kubernetes platform and the workload. Istio is a popular choice for Service Mesh. 

### CLI tools
We need these tools to complete installation.
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes.



