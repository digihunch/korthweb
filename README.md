# Korthweb - Orthanc deployment on Kubernetes
Korthweb project provides two approaches to automatically deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS EC2. 

## TL;DR
Users of this project come from various backgrounds. The business requirement of this project is to deploy Orthanc (stateless app + database) on Kubernetes, to securely host DICOM and web workloads. To automate this effor, we have to incorporate the following configurations:

* Ingress (Istio or Traefik) TLS termination on HTTP and TCP ports
* Use Cert Manager to provision self-signed certificate
* Traffic routing with Istio (Gateway, Virtual Serivce)
* Istio Installation (using Helm charts or Istioctl)
* Security with Istio (Peer Authentication/mTLS, Authorization Policy)
* Deploy observability addons (Prometheus, Grafana) for Istio
* Use bitnami Helm chart to deploy PostgreSQL
* Build your own Helm Chart to deploy apps
* GitOps with FluxCD for Continuous Deployment

To get started, we need a Kubernetes cluster. My *[real-quicK-cluster](https://github.com/digihunch/real-quicK-cluster)* project has guidance to provision a demo cluster real quick (with a couple commands). Apart from a cluster, you will also need the following tools on the client side:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. It is used in all three approaches to install third party charts such as PostgreSQL
* [istioctl](https://helm.sh/docs/intro/install/): istioctl is an alternative to helm to install istio manually.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is *flux*.
## Approach
We started this project with a collection of manifests to apply manually. To automate the deployment, we baked them into a Helm chart. To tackle growing complexity, we then added GitOps approach. The table below summarizes the differences: 

| Approach | Components | Summary |
|--|--|--|
| [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager<br> - Multi-tenancy <br> - Observability| - Includes YAML manifests required for GitOps-based automated deployment using FluxCD. <br> - Take this approach for complete feature set with a powerful deployment workflow. <br> - Two tenants/environments (dev and tst) are deployed.
| [Helm Chart](https://github.com/digihunch/korthweb/tree/main/helm) | - Traefik Ingress <br> - PostgreSQL | - Includes the Helm chart to configure Orthanc and its dependencies with a single command. <br> - Take this approach for simplicity with essential features.
| [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager <br> - Observability (Lite) | - Includes YAML manifests for all required resources for users to manually apply. <br> - Take this approach ONLY for troubleshooting or learning. |

The sub-directories for each approach contains their specific instructions. The approaches do not include exactly the same components. The GitOps approach is the most complete and is a reference for DevOps professionals. The Helm Chart approach is good for clinical support professionals who are not overly concerned with deployment methodologies, and just want a working installation.

## Architectural Considerations
This section discusses the patterns and choice of tools.
### Database
Orthanc supports a range of database backends. In this  project we choose PostgreSQL. We also include deployment of PostgreSQL on Kubernetes with HA. In production, however, it is almost always preferable to host database via managed services if it is provided by the platform. Hosting database (stateful workload) within Kubernetes can be uncessarily involving.
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


