
# Platform Toolings
This page discusses the choice of tools used in Korthweb deployment. Below is a summary of the technologies adopted in the Korthweb deployment process.

## Ingress
At container level, Orthanc uses TCP port 8042 for web traffic, and TCP port 4242 for DICOM traffic. On Kubernetes, we use ingress to expose both ports (443 for web and 11112 for DICOM). The ingress controller also does TLS termination and load balancing.

The Helm chart driven option uses [Traefik](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/) CRD for Ingress. The GitOps driven and manual approaches uses Istio Ingress CRD. For more details, read [my post](https://medium.com/slalom-build/managing-ingress-traffic-on-kubernetes-platforms-ebd537cdfb46) on how to choose the right ingress technology.  

## Istio
[Service mesh](https://www.digihunch.com/2021/12/from-ingress-to-gateway-why-you-need-istio-gateways-on-kubernetes-platforms/) acts as an intermediary layer between the application workload and the underlying platform. This layer commoditizes a variety of common features, such as tracing, mTLS, traffic routing and management. While an application may choose build these features natively in its own code, the idea of service mesh is to allow application developer to focus on the business logic and push networking concerns to this intermediary layer.

Istio is a service mesh product. We use it for Ingress, TLS termination, mTLS, authorization and observability. Once deployed, service-to-service connections (e.g. application to database) automatically take place in mTLS and there is no need to explicitly configure TLS on database connection, as is done in the Helm Chart approach.

We need to control ingress traffic from client into the K8s cluster with an Ingress Controller, e.g. request routing, TLS termination Korthweb uses **Traefik CRD**, or **Istio Ingress CRD** for this requirement.

## Observability
Applications today are released as container images and are hosted as [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/), which brings new challenges to observability.

Istio supports observability add-ons, such as Prometheus to expose envoy (Istio sidecar) metrics and Grafana and Kiali for dashboard display. In manual or GitOps approaches, Kiali is neither exposed on Ingress gateway, or integrated with any IAM system. To access Kiali, we can use port-forwarding. Refer to the instruction in each approach.

We need to measure responsiveness of requests and trace requests to Orthanc. Korthweb utilizes observability addons such as **Prometheus** and **Grafana**

## Helm
We play with Helm in two ways: reusing other's Chart and building our own. Bitnami publishes Helm Charts for common applications (e.g. [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql-ha)) and we simply piggyback on their great work wherever applicable, by deploying their Charts in our platform.

In addition, with the Helm Chart approach, we also build our own Helm Chart (named *orthanc*) to package Orthanc workload along with dependencies. Our Helm chart makes Orthanc deployment a single command. We did not include Istio in this approach for simplicity. Instead of Istio as Gateway, we use Traefik CRD for Ingress.

## FluxCD 
FluxCD is a tool to drive GitOps-based deployment. GitOps is a relatively new deployment approach. With GitOps, source of truth about the deployment is declared in the GitOps directory of this repository or your fork. FluxCD is installed in the target cluster, which watches the source and keeps the target kubernetes cluster state in sync. The GitOps directory serves as the source for deployment. Read the instruction in the directory for more details.

The GitOps approach is more flexible than the Helm approach and can accomodate many deployment techniques. However it is more complicated to use than the Helm approach.

## DICOM Testing
Regardless of deployment option, users need to validate DICOM capability. Each option provides dcmtk commands running C-ECHO and C-STORE against their respective DICOM endpoints. All DICOM communication are TLS enabled and correct testing involves understanding of how TLS works. Read my [blog post](https://www.digihunch.com/2023/02/dicom-testing-with-tls/) on DICOM testing guidelines. 

In addition, the automated deployment needs provision self-signed certificates and reference them accordingly. Korthweb uses **Cert Manager** to meet this requirement.

Korthweb provides artifacts to automatically deploy all the foundational services as discussed above. 