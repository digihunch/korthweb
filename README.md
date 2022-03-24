# Korthweb - Orthanc deployment on Kubernetes
Korthweb project provides two approaches to automatically deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS EC2. 

## TL;DR
Depending on your background, you may use different parts of this project as an example of the following configurations:

* Deploying orthanc on Kubernetes
* DICOM and web workload on Kubernetes
* GitOps with FluxCD for Continuous Deployment
* Traffic routing with Istio (Gateway, Virtual Serivce)
* Istio installation (using helm or istioctl)
* Security with Istio (Peer Authentication/mTLS, Authorization Policy)
* Deployment of Observability addons for Istio
* Use Helm chart to deploy PostgreSQL
* Build your own Helm Chart
* Use Traefik CRD for Ingress
* Use Cert Manager

To get started, we need a Kubernetes cluster. My *[real-quicK-cluster](https://github.com/digihunch/real-quicK-cluster)* project has guidance to provision a demo cluster real quick (with a couple commands).

## Deployment Approach
In this project we explore two approaches for Orthanc deployment, along with a manual approach. Files required for each approach are stored in their own sub-directory with their instructions. The table below is an overview:
| Approach | Components | Summary |
|--|--|--|
| [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager<br> - Multi-tenancy <br> - Observability| - Includes YAML manifests required for GitOps-based automated deployment using FluxCD. <br> - Take this approach for complete feature set with a powerful deployment workflow. <br> - Two tenants/environments (dev and tst) are deployed.
| [Helm Chart](https://github.com/digihunch/korthweb/tree/main/helm) | - Traefik Ingress <br> - PostgreSQL | - Includes the Helm chart to configure Orthanc and its dependencies with a single command. <br> - Take this approach for simplicity with essential features.
| [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | - Istio Ingress <br> - Other Istio Features <br> - PostgreSQL <br> - Cert-Manager <br> - Observability (Lite) | - Includes YAML manifests for all required resources for users to manually apply. <br> - Take this approach ONLY for troubleshooting or learning. |

For detailed instructions, go to the sub-directory named after the intended approach. Depending on the approach, the following tools need to be installed:
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. It is used in all three approaches to install third party charts such as PostgreSQL
* [istioctl](https://helm.sh/docs/intro/install/): istioctl is an alternative to helm to install istio manually.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is *flux*.

## Architectural Considerations
This section discusses the choice of deployment patterns and tools. 
### Database
Orthanc supports many kinds of database backends. This deployment project is built on PostgreSQL database only, and it includes installing PostgreSQL database in HA. However, if the Kubernetes platform is hosted in a public cloud environment, it is almost always preferable to host database as managed services provided by the platform. Hosting database (stateful workload) within Kubernetes can be uncessarily involving.
### Ingress Gateway
The Orthanc container uses TCP port 8042 for web traffic, and TCP port 4242 for DICOM traffic. In Kubernetes, we use ingress to expose both ports (443 for web and 11112 for DICOM) for TLS termination and load balancing across Pods. So we need an Ingress controller that can proxy both HTTP and TCP traffic, as well as perform TLS termination.

In the Helm approach, we use [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/) CRD for this requirement. Both the GitOps and Manual approaches come with Istio service mesh so we simply use the Istio provided Gateways to satisfy the same requirement. I did not include Istio service mesh in the Helm approach because Istio's Helm chart is still maturing in Jan 2022 and I don't want to make my Helm Chart overly complicated. In GitOps and Manual approaches, I did not use Traefik because Istio already provides the needed gateway function. 

### The Role of Istio
Applications are released as [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/) today. [Service mesh](https://www.digihunch.com/2021/12/from-ingress-to-gateway-why-you-need-istio-gateways-on-kubernetes-platforms/) acts as an intermediary layer between the application workload and the underlying platform. This layer commoditizes a variety of common features related to observability (e.g. tracing), security (e.g. mTLS, authorization), traffic management (e.g. ingress and egress, traffic splitting), and resiliency (circuit breaking, retry/timeout). While an application may choose provide those features natively in its own code, the idea of service mesh is to deliver these features as the infrastructure layer, such that application developer can only focus on the function.

Istio is a popular choice for service mesh. In this project we use it for Ingress, TLS termination, mTLS, authorization and observability. Once Istio is deployed (e.g. in GitOps and manual approaches with PeerAuthentication at strict mode for mTLS), service-to-service connections (e.g. application to database) are automatically configured with mTLS and there is no need to explicitly configure TLS on database connection.

### Observability
In GitOps and manual approaches, we install observability add-ons along with Istio, including Prometheus to expose envoy (Istio sidecar) metrics, grafana and Kiali for dashboard. In this vanilla setup, Kiali is neither exposed on Ingress gateway, or integrated with any IAM system. To access Kiali, we can use port-forwarding. Refer to the instruction in each approach.
### Helm
We may interact with Helm in two ways: reusing other's Chart and building our own. Renowned third-party such as Bitnami publishes Helm Charts for common workload (e.g. PostgreSQL) and we simply use their chart in each deployment option wherever applicable. In the Helm approach, we also build our own Helm Chart (named *orthanc* ) to deploy Orthanc workload along with dependencies. Our Helm chart makes Orthanc deployment a single command. 

As mentioned above, the Helm approach does not deploy Istio as Istio's Helm chart is still maturing. Instead it installs Traefik CRD as ingress.

### FluxCD 

FluxCD is a tool for GitOps-based deployment. GitOps is a relatively new deployment approach. With GitOps, source of truth about the deployment is declared in the GitOps directory of this repository or your fork. A tool (e.g. FluxCD in this case) is installed in the target cluster and it watches the source and keeps the target kubernetes cluster in sync. To install FluxCD, we need to bootstrap the cluster following the instruction in GitOps directory.

The GitOps approach is more flexible than the Helm approach and can accomodate many deployment techniques. However it is more complicated to use than the Helm approach.

### TLS Certificate
 In this project, we provision [self-signed certificate](https://www.digihunch.com/2022/01/creating-self-signed-x509-certificate/) because TLS is mandatory. This is done with Cert Manager (in GitOps and manual approaches), or Helm template function (in Helm approach). Certificates are kept in Kubernetes as Secret. You may export a certificate to a file:
```sh
kubectl -n orthweb get secret orthweb-secret -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
```
In production, you may bring your own certificates or integration with existing PKI workflow.

For deployment customization, you may contact [Digi Hunch](https://www.digihunch.com/) for professional services. 
