# Korthweb - Orthanc deployment on Kubernetes
Korthweb is an open-source project to deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes platform. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb provides a number of deployment approaches. Korthweb is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS EC2. 

## Kubernetes Cluster
Regardless of which deployment approach, this project requires a Kubernetes cluster. If you do not have one ready, refer to the instruction in the *[cluster](https://github.com/digihunch/korthweb/tree/main/cluster)* directory to build a Kubernetes cluster first. A playground cluster can be created with a couple commands.

## Deployment Approach
This project explores the following deployment approaches. Each approach has its own sub-directory with instruction in their respective sub-directory.
| Option | Tools | Components | Activity |
|--|--|--|--|
| [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | kubectl, helm, Istioctl | Istio CRD for ingress, Istio Service Mesh with mTLS, PostgreSQL and Orthanc  | Use YAML manifests from this sub-directory along with external Helm charts to install Istio, PostgreSQL and Orthanc workload step-by-step. Take this approach only for troubleshooting and learning. For automation, users should go with the GitOps approach. |
| [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | kubectl, helm, flux |Same as above.| The files in this sub-directory defines the state of workload, including Istio, PostgreSQL and Orthanc. FluxCD sync the configuration to the Kubernetes cluster. Istio provides mTLS between services, and Ingress for north-south traffic. Users take this approach to deploy workload without dealing with deployment details.
| [Helm Chart](https://github.com/digihunch/korthweb/tree/main/helm) | kubectl, helm |Traefik's CRD for ingress; PostgreSQL and Orthanc (with TLS connection) | This sub-directory provides a Helm chart named Orthanc, which references external charts (e.g. PostgreSQL, Traefik) and configures Orthanc workload. The Chart configures TLS between Orthanc and PostgreSQL. This option uses Traefik's CRD for TLS termination for both HTTP and DICOM traffic

The Helm Chart option has stopped updating. In each option, one or more of the following tools are used:
* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/).
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. It is used in all three approaches to install third party charts such as PostgreSQL
* [istioctl](https://helm.sh/docs/intro/install/): istioctl is an alternative to helm to install istio manually.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is *flux*.

For detailed instructions with each option, please go to the sub-directory that represents the intended option.

## Architectural Considerations
This section discusses the choice of deployment patterns and tools. To host Orthanc application in a minimum viable deployment, the following tiers are currently included:
| Component | Tier | Description |
|--|--|--|
| Istio or Traefik| Ingress| The Ingress tier receives external traffic for TCP and HTTP and performs TLS termination before proxying the traffic to their respect ports. Istio is used in the manual and GitOps options. For the Helm Option, Traefic is used.|
|Orthanc|Application|The front end workload using official Docker image released by Orthanc. The Pods are managed as Kubernetes Deployment. Each Pod connects to PostgreSQL service for database and image storage. Two TCP ports are exposed, 8042 for HTTP traffic, and 4242 for DICOM traffic, as ClusterIP service.
|PostgreSQL|Database|If available, a managed database instance should be used. The Korthweb project assumes that no managed PostgreSQL service is available, therefore it deploys Postgres HA instance using Bitnami's Helm Chart. It also requires persistent volumes available to the Kubernetes cluster. |
|Istio|Service Mesh|Only available for manual and GitOps options, this tier provides mTLS between services, and potentially observability features. 

The purpose of Korthweb deployment project is to install all tiers and ensure they are integrated and functional as intended.

### Ingress Gateway
Originally I was looking for an Ingress controller that can proxy both HTTP and TCP traffic, as well as perform TLS termination. Traefik appears to be the best choice. Further along I discovered the benefit of using a [service mesh](https://www.digihunch.com/2021/12/from-ingress-to-gateway-why-you-need-istio-gateways-on-kubernetes-platforms/) for  [microservices](https://www.digihunch.com/2021/11/from-microservice-to-service-mesh/). Essentially, with a separate layer between the workload and the platform, service mesh commoditizes many common features related to observability (e.g. tracing), security (e.g. mTLS), traffic management (e.g. ingress and egress, traffic splitting), and resiliency (circuit breaking, retry/timeout). 

Istio is a popular choice for Service Mesh. In this project, we mainly use istio for Ingress, TLS termination, mTLS and observability. If Istio is present, there is no need to explicitly configure TLS between application and database, because by default Istio's [sidecar](https://istio.io/latest/docs/ops/configuration/traffic-management/tls-configuration/) applies mTLS to all connections.


### Helm
We may interact with Helm in two ways: using a chart released by third party, and build our own chart. Even in the manual approach, we run third-party Helm Charts for simplicity. There is no point to reinvent the wheel and deploy every tier (e.g. Postgres HA) manually. The Charts provided by well-known third-party are very reliable.

In our Helm Chart deployment option, we build our own Helm Chart called *orthanc* in an attempt to consoliate all deployment activities. This orthanc Helm chart includes dependency charts such as PostgreSQL HA. It also includes default configuration options so that user can run deployment with a single command. 

As I realized later the limitations with bundling everything inside of a single Helm Chart, I stopped adding more features to this option. Therefore the Helm Chart option stops short of an Ingress to terminate TLS. It is not being update any more and is considered legacy.

### GitOps 
With GitOps, source of truth about the deployment is declared in this repo's GitOps directory, and a tool (in our project, FluxCD) is used to keep the target kubernetes cluster in sync. FluxCD is a popular tool for GitOps. Our GitOps deployment option still employs external Helm charts, but at a higher level the application can be managed using Kustomize. Therefore not everything has to be built as part of Helm Chart. 

### TLS Certificate
In this project, we provision self-signed certificate to get the website up and running. In real deployment, a validate certificate issued by a CA should be used instead. In the GitOps and manual approach, we use Cert Manager to provision certificates. In the Helm approach, we use Helm template functin. For more details, refer to [this](https://www.digihunch.com/2022/01/creating-self-signed-x509-certificate/) post. The name of the Kubernetes Secret that keeps the certificate is different among the approaches, but they can all be exported with kubectl tool, for example:
```sh
kubectl -n orthweb get secret dicom.orthweb.com -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt
```
The name of secret is provided in the instruction of each deployment approach.


