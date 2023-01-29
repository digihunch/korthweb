
# Korthweb - Orthanc on Kubernetes

<a href="https://www.orthanc-server.com/"><img style="float" align="right" src=".asset/orthanc_logo.png"></a>

[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?logo=kubernetes&logoColor=white)](https://www.kubernetes.io)
[![Helm](https://img.shields.io/badge/helm-%230f1689.svg?logo=helm&logoColor=white)](https://helm.sh/)
[![fluxcdbadge](https://img.shields.io/static/v1?label=&message=fluxcd&color=fec007&logo=data:image/svg+xml;base64,PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB4PSIwcHgiIHk9IjBweCIKCSB2aWV3Qm94PSIwIDAgNjQgNjQiIHdpZHRoPSI2NCIgaGVpZ2h0PSI2NCIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgNjQgNjQ7IiB4bWw6c3BhY2U9InByZXNlcnZlIj4KPHN0eWxlIHR5cGU9InRleHQvY3NzIj4KCS5zdDB7ZmlsbDojMzI2Q0U1O30KCS5zdDF7ZmlsbDojQzFEMkY3O30KCS5zdDJ7ZmlsbDpub25lO30KPC9zdHlsZT4KPGc+Cgk8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMTAuMSwxN2MtMC45LTAuNi0xLjEtMS43LTAuNS0yLjZjMC4xLTAuMiwwLjMtMC40LDAuNS0wLjVMMzEsMC4zYzAuNi0wLjQsMS40LTAuNCwyLDBsMjAuOSwxMy42CgkJYzAuOSwwLjYsMS4xLDEuNywwLjUsMi42Yy0wLjEsMC4yLTAuMywwLjQtMC41LDAuNUwzMywzMC41Yy0wLjYsMC40LTEuNCwwLjQtMiwwTDEwLjEsMTd6Ii8+Cgk8cGF0aCBjbGFzcz0ic3QxIiBkPSJNMzUuMywxOS40aDEuNGMwLjYsMCwxLjEtMC41LDEuMS0xLjFjMC0wLjItMC4xLTAuNC0wLjEtMC41TDMzLDkuNWMtMC4zLTAuNS0xLTAuNy0xLjUtMC40CgkJYy0wLjIsMC4xLTAuMywwLjItMC40LDAuNGwtNC43LDguMmMtMC4zLDAuNS0wLjEsMS4yLDAuNCwxLjVjMC4yLDAuMSwwLjQsMC4xLDAuNSwwLjFoMS40YzAuNiwwLDEuMSwwLjUsMS4xLDEuMWwwLDB2OS40bDEsMC42CgkJYzAuNywwLjUsMS43LDAuNSwyLjQsMGwxLTAuNnYtOS40QzM0LjIsMTkuOSwzNC43LDE5LjQsMzUuMywxOS40QzM1LjMsMTkuNCwzNS4zLDE5LjQsMzUuMywxOS40eiIvPgoJPHBhdGggY2xhc3M9InN0MiIgZD0iTTMxLDYzLjdjMC4yLDAuMSwwLjQsMC4yLDAuNiwwLjNjLTAuNC0wLjItMC44LTAuNC0xLjItMC42TDMxLDYzLjd6IE0yOS44LDM0LjJsLTIuMSwxLjMKCQljMC43LDAuNCwxLjQsMC44LDIuMSwxLjJWMzQuMnogTTM0LjIsMzguNmMxLjgsMC42LDMuNiwxLDUuNSwxLjVjMiwwLjUsNCwxLDYsMS42bC02LjUtNC4yYy0xLjctMC41LTMuNC0xLTUtMS43TDM0LjIsMzguNnoKCQkgTTM0LjIsNDkuOVY1MGMwLDAuNS0wLjUsMC45LTEuMSwwLjloLTIuMmMtMC42LDAtMS4xLTAuNC0xLjEtMC45di0xLjJjLTQuNi0xLjItOS4xLTIuNi0xMy02LjJsLTIuNywxLjdjNC4xLDQsOS4yLDUuMywxNC42LDYuNgoJCWM1LDEuMiwxMC4xLDIuNSwxNC40LDYuMWwyLjctMS43QzQyLjUsNTIuMywzOC40LDUxLDM0LjIsNDkuOXogTTE2LjMsNTQuMWw3LjEsNC42YzMuNywwLjksNy40LDIuMSwxMC43LDQuM2wyLjctMS44CgkJYy0zLjYtMi41LTcuOC0zLjUtMTIuMS00LjZDMjEuOCw1NiwxOSw1NS4zLDE2LjMsNTQuMXogTTI5LjgsMzkuMWMtMS40LTAuNi0yLjctMS40LTMuOS0yLjNsLTIuNywxLjhjMiwxLjYsNC4zLDIuNiw2LjYsMy40CgkJTDI5LjgsMzkuMXogTTM5LjIsNDIuMWMtMS43LTAuNC0zLjMtMC44LTUtMS4zdjIuNWMwLjYsMC4yLDEuMiwwLjMsMS45LDAuNWM1LjUsMS4zLDExLjEsMi43LDE1LjcsNy4zYzAuMSwwLjEsMC4yLDAuMiwwLjMsMC4zCgkJbDEuOC0xLjJjMC4zLTAuMiwwLjUtMC40LDAuNi0wLjdjLTAuMi0wLjItMC40LTAuNC0wLjYtMC42QzQ5LjgsNDQuNyw0NC42LDQzLjQsMzkuMiw0Mi4xTDM5LjIsNDIuMXogTTM1LjYsNDUuNwoJCWMtMC41LTAuMS0wLjktMC4yLTEuNC0wLjN2Mi40YzQuNywxLjIsOS41LDIuNywxMy40LDYuNGwyLjctMS43YzAsMCwwLDAsMCwwQzQ2LjEsNDguMyw0MSw0Ny4xLDM1LjYsNDUuN3ogTTI5LjgsNDQuMQoJCWMtMy0xLTUuOS0yLjMtOC41LTQuNGwtMi43LDEuN2MzLjMsMi44LDcuMSw0LjEsMTEuMiw1LjJWNDQuMXoiLz4KCTxwYXRoIGNsYXNzPSJzdDIiIGQ9Ik0xMi42LDQ1LjdjLTAuMS0wLjEtMC4xLTAuMS0wLjItMC4yTDEwLjEsNDdjLTAuMSwwLjEtMC4yLDAuMi0wLjMsMC4zYzAuMiwwLjIsMC40LDAuNCwwLjYsMC42CgkJYzQuMSw0LjEsOS4zLDUuNCwxNC43LDYuN2M0LjYsMS4xLDkuNCwyLjMsMTMuNSw1LjRsMi43LTEuOGMtMy44LTMtOC4zLTQuMS0xMy4xLTUuM0MyMi44LDUxLjcsMTcuMSw1MC4zLDEyLjYsNDUuN0wxMi42LDQ1Ljd6Ii8+Cgk8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMzkuMiwzNy41bC01LTMuM3YxLjVDMzUuOCwzNi41LDM3LjUsMzcsMzkuMiwzNy41eiBNMzQuMiwzOC42djIuMmMxLjcsMC41LDMuMywwLjksNSwxLjMKCQljNS40LDEuMywxMC42LDIuNiwxNC43LDYuN2MwLjIsMC4yLDAuNCwwLjQsMC42LDAuNmMwLjQtMC45LDAuMi0xLjktMC42LTIuNGwtOC4yLTUuM2MtMi0wLjctNC0xLjItNi0xLjYKCQlDMzcuOCwzOS42LDM2LDM5LjEsMzQuMiwzOC42TDM0LjIsMzguNnogTTI5LjgsMzYuOGMtMC43LTAuNC0xLjQtMC44LTIuMS0xLjJsLTEuOSwxLjJjMS4yLDAuOSwyLjYsMS43LDMuOSwyLjNMMjkuOCwzNi44egoJCSBNMzYuMSw0My43Yy0wLjYtMC4yLTEuMi0wLjMtMS45LTAuNXYyLjFjMC41LDAuMSwwLjksMC4yLDEuNCwwLjNjNS40LDEuMywxMC42LDIuNiwxNC43LDYuN2MwLDAsMCwwLDAsMGwxLjgtMS4xCgkJYy0wLjEtMC4xLTAuMi0wLjItMC4zLTAuM0M0Ny4yLDQ2LjQsNDEuNSw0NS4xLDM2LjEsNDMuN3ogTTI5LjgsNDJjLTIuNC0wLjgtNC42LTEuOS02LjYtMy40bC0xLjgsMS4yYzIuNiwyLjEsNS41LDMuNCw4LjUsNC40VjQyCgkJeiBNMjkuOCw0Ni43Yy00LjEtMS4xLTcuOS0yLjQtMTEuMi01LjJsLTEuOCwxLjJjMy44LDMuNSw4LjQsNSwxMyw2LjJWNDYuN3ogTTM0LjIsNDkuOWM0LjMsMS4xLDguMywyLjQsMTEuNiw1LjRsMS44LTEuMgoJCWMtNC0zLjctOC43LTUuMi0xMy40LTYuNEwzNC4yLDQ5Ljl6IE0xNC4yLDQ0LjRsLTEuOCwxLjJjMC4xLDAuMSwwLjEsMC4xLDAuMiwwLjJjNC41LDQuNSwxMC4yLDUuOSwxNS43LDcuMwoJCWM0LjcsMS4yLDkuMywyLjMsMTMuMSw1LjNsMS44LTEuMmMtNC4zLTMuNi05LjQtNC45LTE0LjQtNi4xQzIzLjQsNDkuNywxOC4zLDQ4LjQsMTQuMiw0NC40eiBNMTAuNCw0Ny45Yy0wLjItMC4yLTAuNC0wLjQtMC42LTAuNgoJCWMtMC43LDAuNy0wLjcsMS45LDAsMi42YzAuMSwwLjEsMC4yLDAuMiwwLjMsMC4ybDYuMSw0YzIuNywxLjEsNS42LDEuOCw4LjQsMi41YzQuNCwxLjEsOC41LDIuMSwxMi4xLDQuNmwxLjktMS4yCgkJYy00LjEtMy4xLTguOS00LjMtMTMuNS01LjRDMTkuNyw1My4zLDE0LjUsNTIsMTAuNCw0Ny45TDEwLjQsNDcuOXogTTMwLjQsNjMuM2MwLjQsMC4yLDAuOCwwLjQsMS4yLDAuNmMwLjUsMC4xLDEsMCwxLjQtMC4zbDEtMC43CgkJYy0zLjMtMi4yLTctMy4zLTEwLjctNC4zTDMwLjQsNjMuM3oiLz4KPC9nPgo8L3N2Zz4K)](https://fluxcd.io/)
[![Istio](https://img.shields.io/badge/istio-%23466bb0.svg?logo=istio&logoColor=white)](https://www.istio.io/)
[![TraefikProxy](https://img.shields.io/badge/traefikproxy-%2324a1c1.svg?logo=traefikproxy&logoColor=white)](https://traefik.io/traefik/)
[![Prometheus](https://img.shields.io/badge/prometheus-%23e6522c.svg?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/grafana-%23f46800.svg?logo=grafana&logoColor=white)](https://grafana.com/)
[![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Latest Release](https://img.shields.io/github/v/release/digihunch/korthweb)](https://github.com/digihunch/korthweb/releases/latest) 

Korthweb project provides different approaches to deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS. 

## TL;DR
Users of this project may come from various backgrounds. The business requirement of this project is to deploy Orthanc (stateless app + database) on Kubernetes, to securely host DICOM and web workloads. To automate this effort, I have to incorporate the following configurations:

* Ingress (Istio or Traefik) TLS termination on HTTP and TCP ports
* Use Cert Manager to provision self-signed certificate
* Traffic routing with Istio (Gateway, Virtual Serivce)
* Istio Installation (using Helm charts or Istioctl)
* Security with Istio (Peer Authentication/mTLS, Authorization Policy)
* Deploy observability addons (Prometheus, Grafana) for Istio
* Use bitnami Helm chart to deploy PostgreSQL
* Build your own Helm Chart to deploy Orthanc
* GitOps with FluxCD for Continuous Deployment

To get started, you need a Kubernetes cluster. My *[real-quicK-cluster](https://github.com/digihunch/real-quicK-cluster)* project has guidance to provision a demo cluster real quick (with a couple commands). Apart from a cluster, you will also need the following tools on the client side:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. It is used in all three approaches to install third party charts such as PostgreSQL
* [istioctl](https://helm.sh/docs/intro/install/): istioctl is an alternative to helm to install istio manually.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is *flux*.
## Automation Approach
I started this project by manually applying a few manifests. For templating capability, I then baked them into a Helm chart. For faster iteration, I then added a GitOps approach. As a result, the project today consists of three automation levels: manual, Helm Chart, and GitOps. The table below summarizes the differences among these automation levels:

| Automation Approach | Components Installed | Highlights |
|--|--|--|
| #1 [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager<br> - Multi-tenancy <br> - Observability| - Includes YAML manifests required for GitOps-based automated deployment using FluxCD. <br> - Take this approach for best practices with continuous deployment. <br> - Two instances  (for two fictitious healthcare facilities named BHC and MHR) are deployed.
| #2 [Helm Chart](https://github.com/digihunch/korthweb/tree/main/helm) | - Traefik Ingress <br> - PostgreSQL | - Includes the Helm chart to configure Orthanc and its dependencies with a single command. <br> - Take this approach to quickly install Orthanc on Kubernetes.
| #3 [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager <br> - Observability (Lite) | - Includes YAML manifests for all required resources for users to manually apply. <br> - Take this approach ONLY for troubleshooting or learning. |

The artifacts of each automation approach are kept in their eponymous sub-directories. As the table above suggests, go with the GitOps approach for deployment capability. Go with the Helm Chart approach for quick installation.

## Architectural Considerations
Orthanc with its dependencies in production must be configured with scalability, resiliency and high availability. Even though Korthweb is a starting point with minimum configuration, there is no one-size-fit-all solution design, I included a [separate guideline](https://github.com/digihunch/korthweb/blob/main/SolutionGuideline.md) for database and image storage. The rest of this section discusses networking, security and deployment automation.

### Ingress
At container level, Orthanc uses TCP port 8042 for web traffic, and TCP port 4242 for DICOM traffic. On Kubernetes, we use ingress to expose both ports (443 for web and 11112 for DICOM). The ingress controller also does TLS termination and load balancing.

In the Helm approach, we use [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/) CRD for Ingress. In GitOps and Manual approaches where we install Istio, we use Istio Gateway as Ingress.  

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