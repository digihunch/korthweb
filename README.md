
# Korthweb - Orthanc on Kubernetes

<a href="https://www.orthanc-server.com/"><img style="float" align="right" src=".asset/orthanc_logo.png"></a>

[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?logo=kubernetes&logoColor=white)](https://www.kubernetes.io)
[![Helm](https://img.shields.io/badge/helm-%230f1689.svg?logo=helm&logoColor=white)](https://helm.sh/)
[![Istio](https://img.shields.io/badge/istio-%23466bb0.svg?logo=istio&logoColor=white)](https://www.istio.io/)
[![TraefikProxy](https://img.shields.io/badge/traefikproxy-%2324a1c1.svg?logo=traefikproxy&logoColor=white)](https://traefik.io/traefik/)
[![Prometheus](https://img.shields.io/badge/prometheus-%23e6522c.svg?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/grafana-%23f46800.svg?logo=grafana&logoColor=white)](https://grafana.com/)
[![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

[![fluxcdbadge](https://img.shields.io/static/v1?label=Gitops&message=FluxCD&color=3d6ddd)](https://fluxcd.io/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Latest Release](https://img.shields.io/github/v/release/digihunch/korthweb)](https://github.com/digihunch/korthweb/releases/latest) 

Korthweb provides three options to deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb focues on the deployment. It is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS. 

## TL;DR
 The business requirement of this project is to deploy Orthanc (stateless app + database) on Kubernetes, to securely host DICOM and web workloads. To automate this effort, I have to incorporate the following configurations:

* Ingress (Istio or Traefik) TLS termination on HTTP and TCP ports
* Use Cert Manager to provision self-signed certificate
* Traffic routing with Istio (Gateway, Virtual Serivce)
* Istio Installation (using Helm charts or Istioctl)
* Security with Istio (Peer Authentication/mTLS, Authorization Policy)
* Deploy observability addons (Prometheus, Grafana) for Istio
* Use bitnami Helm chart to deploy PostgreSQL
* Build your own Helm Chart to deploy Orthanc
* GitOps with FluxCD for Continuous Deployment

To get started, you need a Kubernetes cluster. My *[real-quicK-cluster](https://github.com/digihunch/real-quicK-cluster)* project has guidance to provision a demo cluster real quick. Apart from a cluster, you will also need the following tools on the client side:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. It is used in all three approaches to install third party charts such as PostgreSQL
* [istioctl](https://helm.sh/docs/intro/install/): istioctl is an alternative to helm to install istio manually.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is *flux*.

## Deployment Options
The project  consists of three deployment options: GitOps, Helm Chart driven, and manual. The table below summarizes the differences:

| Deployment Option | Components Installed | Highlights |
|--|--|--|
| #1 [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager<br> - Multi-tenancy <br> - Observability| - Includes YAML manifests required for GitOps-based automated deployment using FluxCD. <br> - Take this approach for continuous deployment and end-to-end automation. <br> - Two instances are deployed, for two fictitious healthcare facilities acronymed BHC and MHR.
| #2 [Helm Chart](https://github.com/digihunch/korthweb/tree/main/helm) driven | - Traefik Ingress <br> - PostgreSQL | - Includes the Helm chart to configure Orthanc and its dependencies with a single command. <br> - Take this approach to quickly install Orthanc on Kubernetes.
| #3 [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager <br> - Observability (Lite) | - Includes YAML manifests for all required resources for users to manually apply. <br> - This option is considered legacy. Consider this option ONLY for troubleshooting or learning. |

The artifacts of each deployment option are stored in eponymous sub-directories. As the table above suggests, go with the GitOps driven approach for rich capabilities and automation level.

## FAQ
Orthanc with its dependencies in production must be configured with scalability, resiliency and high availability. Even though Korthweb is a starting point with minimum configuration, there is no one-size-fit-all solution design, I included a [separate guideline](https://github.com/digihunch/korthweb/blob/main/SolutionGuideline.md) for database and image storage. The rest of this section discusses networking, security and deployment automation.

### Ingress
At container level, Orthanc uses TCP port 8042 for web traffic, and TCP port 4242 for DICOM traffic. On Kubernetes, we use ingress to expose both ports (443 for web and 11112 for DICOM). The ingress controller also does TLS termination and load balancing.

The Helm chart driven option uses [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/) CRD for Ingress. The GitOps driven and manual approaches uses Istio Ingress CRD. For more details, read [my post](https://medium.com/slalom-build/managing-ingress-traffic-on-kubernetes-platforms-ebd537cdfb46) on how to choose the right ingress technology.  

### Istio
[Service mesh](https://www.digihunch.com/2021/12/from-ingress-to-gateway-why-you-need-istio-gateways-on-kubernetes-platforms/) acts as an intermediary layer between the application workload and the underlying platform. This layer commoditizes a variety of common features, such as tracing, mTLS, traffic routing and management. While an application may choose build these features natively in its own code, the idea of service mesh is to allow application developer to focus on the business logic and push networking concerns to this intermediary layer.

Istio is a service mesh product. We use it for Ingress, TLS termination, mTLS, authorization and observability. Once deployed, service-to-service connections (e.g. application to database) automatically take place in mTLS and there is no need to explicitly configure TLS on database connection, as is done in the Helm Chart approach.

### Observability
Applications today are released as container images and are hosted as [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/), which brings new challenges to observability.
Istio supports observability add-ons, such as Prometheus to expose envoy (Istio sidecar) metrics and Grafana and Kiali for dashboard display. In manual or GitOps approaches, Kiali is neither exposed on Ingress gateway, or integrated with any IAM system. To access Kiali, we can use port-forwarding. Refer to the instruction in each approach.

### Helm
We play with Helm in two ways: reusing other's Chart and building our own. Bitnami publishes Helm Charts for common applications (e.g. [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql-ha)) and we simply piggyback on their great work wherever applicable, by deploying their Charts in our platform.. In addition, with the Helm Chart approach, we also build our own Helm Chart (named *orthanc*) to package Orthanc workload along with dependencies. Our Helm chart makes Orthanc deployment a single command. We did not include Istio in this approach for simplicity. Instead of Istio as Gateway, we use Traefik CRD for Ingress.

### FluxCD 
FluxCD is a tool to drive GitOps-based deployment. GitOps is a relatively new deployment approach. With GitOps, source of truth about the deployment is declared in the GitOps directory of this repository or your fork. FluxCD is installed in the target cluster, which watches the source and keeps the target kubernetes cluster state in sync. The GitOps directory serves as the source for deployment. Read the instruction in the directory for more details.

The GitOps approach is more flexible than the Helm approach and can accomodate many deployment techniques. However it is more complicated to use than the Helm approach.

### Security
This project is developed with security in mind. We create [self-signed certificate](https://www.digihunch.com/2022/01/creating-self-signed-x509-certificate/) to secure both DICOM and web traffic. In the Helm approach, we use Helm template to create self-signed certificate. In Gitops and manual approaches, we use cert manager. Certificate and Secrets are stored as Kubernetes secret object. 

### DICOM Testing
Regardless of deployment option, users need to validate DICOM capability. Each option provides dcmtk commands running C-ECHO and C-STORE against their respective DICOM endpoints. All DICOM communication are TLS enabled and correct testing involves understanding of how TLS works. Read my [blog post](https://www.digihunch.com/2023/02/dicom-testing-with-tls/) on DICOM testing guidelines. 
