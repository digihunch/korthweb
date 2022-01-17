# Korthweb - Orthanc deployment on Kubernetes
Korthweb project provides different approaches to automatically deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS EC2. 

## Kubernetes Cluster
Regardless of deployment approach, we need a Kubernetes cluster. If you do not have one already, refer to the instruction in the *[cluster](https://github.com/digihunch/korthweb/tree/main/cluster)* directory to build one first. A simple cluster as a playground only takes with a couple commands to create.

## Deployment Approach
In this project we explore three approaches for Orthanc deployment. Each is stored its own sub-directory with their respective instruction. The table below is a summary:
| Approach | Components | Mechanism |
|--|--|--|
| [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | - Istio CRD Ingress <br> - Istio Service Mesh <br> - PostgreSQL <br> - Cert-Manager | YAML manifests for kubectl apply |
| [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | - Istio CRD Ingress <br> - Istio Service Mesh <br> - PostgreSQL <br> - Cert-Manager<br> - Multi-environment| GitOps YAML manifests for FluxCD
| [Helm Chart](https://github.com/digihunch/korthweb/tree/main/helm) | - Traefik CRD Ingress <br> - PostgreSQL | Helm chart to configure Orthanc and its dependencies. 

For detailed instructions, go to the sub-directory named after the intended approach. Depending on the approach, the following tools need to be installed:
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. It is used in all three approaches to install third party charts such as PostgreSQL
* [istioctl](https://helm.sh/docs/intro/install/): istioctl is an alternative to helm to install istio manually.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is *flux*.

## Architectural Considerations
This section discusses the choice of deployment patterns and tools. 

### Ingress Gateway
Originally I was looking for an Ingress controller that can proxy both HTTP and TCP traffic, as well as perform TLS termination. [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/) CRD serves the purpose well and I use it in the Helm approahc. For the benefit of [service mesh](https://www.digihunch.com/2021/12/from-ingress-to-gateway-why-you-need-istio-gateways-on-kubernetes-platforms/) with [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/), I use Istio in the other approaches. Essentially, with a separate layer between the workload and the platform, service mesh commoditizes many common features related to observability (e.g. tracing), security (e.g. mTLS), traffic management (e.g. ingress and egress, traffic splitting), and resiliency (circuit breaking, retry/timeout). 

Istio is a popular choice for Service Mesh. In this project, we mainly use istio for Ingress, TLS termination, mTLS and observability. If Istio is present, there is no need to explicitly configure TLS between application and database, because by default Istio's [sidecar](https://istio.io/latest/docs/ops/configuration/traffic-management/tls-configuration/) applies mTLS to all connections.
### Helm
We may interact with Helm in two ways: reusing other's Chart and building our own. Renowned third-party such as Bitnami publishes Helm Charts for common workload (e.g. PostgreSQL) and we simply use their chart in each deployment option wherever applicable. In the Helm approach, we also build our own Helm Chart (named *orthanc* ) to deploy Orthanc workload along with dependencies. Our Helm chart makes Orthanc deployment a single command. 

The Helm approach does not deploy Istio as Istio's Helm chart is still maturing. Instead it installs Traefik CRD as ingress.

### FluxCD 
With GitOps, source of truth about the deployment is declared in this repo's GitOps directory, and a GitOps tool (e.g. FluxCD) keeps the target kubernetes cluster in sync. We configure this synchronization mechanism by bootstrapping our cluster using the code provided.

### TLS Certificate
 We provision [self-signed certificate in this project](https://www.digihunch.com/2022/01/creating-self-signed-x509-certificate/). This is done with Cert Manager (in GitOps and manual approaches), or Helm template function (in Helm approach). Certificates are kept in Kubernetes Secret. To export a certificate, use kubectl. For example:
```sh
kubectl -n orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
```