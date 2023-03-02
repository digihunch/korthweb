# Deployment Overview

While Orthanc application focuses on the core features in medical imaging, to operationalize it on Kubernetes platform, we need numerous auxiliary services for automation, traffic management, observability and security. Luckily, the cloud native ecosystem brings a plethora of open-source choices.

## Foundational services

Here is a glance at the technical requirements and how the chosen tools address them:

* The automated deployment needs provision self-signed certificates and reference them accordingly. Korthweb uses **Cert Manager** to meet this requirement.
* We need to control ingress traffic from client into the K8s cluster with an Ingress Controller, e.g. request routing, TLS termination Korthweb uses **Traefik CRD**, or **Istio Ingress CRD** for this requirement.
* We need to measure responsiveness of requests and trace requests. Korthweb utilizes observability addons such as **Prometheus** and **Grafana**
* Orthanc needs a relational database. Korthweb uses **PostgreSQL**
* For additional layer of security, we need to configure Peer Authentication and Authorization. Korthweb uses some **Istio** CRDs
* We need to deploy auxiliary services, Korthweb makes use of community-maintained **Helm Charts** stored in external **Helm Repo** and CLI utilities.
* We need to orchestrate the deployment of Orthanc workloads. Korthweb leverages **FluxCD** for GitOps deployment approach, self-created **Helm Chart** for Helm deployment approach.

Korthweb provides artifacts to automatically deploy all the foundational services as discussed above. 

## Deployment Approaches

There are three deployment approaches. Each approach differs in complexity and level of automation but all lead to a functional Orthanc deployment. The approaches are summarized as below:

| Approach | Components Installed | Key Features and Considerations |
|--|--|--|
| [GitOps](https://github.com/digihunch/korthweb/tree/main/gitops) | - Istio CRD as Ingress <br> - Other Service Mesh features supported by Istio <br> - PostgreSQL <br> - Cert-Manager<br> - Observability <br> - Multi-tenancy| - Includes artifacts for GitOps-based automated deployment using FluxCD. <br> - Take this approach for continuous deployment and end-to-end automation. <br> - Two tenants are deployed, for two fictitious healthcare facilities acronymed BHC and MHR.
| [Helm](https://github.com/digihunch/korthweb/tree/main/helm) | - Traefik CRD as Ingress <br> - PostgreSQL | - Includes the Helm chart to configure Orthanc and its dependencies with a single command. <br> - Take this approach to quickly install Orthanc on Kubernetes.
| [Manual](https://github.com/digihunch/korthweb/tree/main/manual) | - Istio CRD as Ingress <br> - Other Service Mesh features supported by Istio <br> - PostgreSQL <br> - Cert-Manager <br> - Observability (Lite) | - Includes artifacts for users to manually apply. <br> - Consider this option ONLY for troubleshooting or learning deployment|

The artifacts of each approach are stored in eponymous sub-directories. Korthweb recommends the GitOps approach.

## CLI tools
During the deployment process, we need a variety of CLI tools to interact with the cluster, such as:

* [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl): connect to API server to manage the Kubernetes cluster. With multiple clusters, you need to [switch context](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/). We need it in all three approaches.
* [helm](https://helm.sh/docs/intro/install/): helm is package manager for Kubernetes. The name of Helm's CLI tool is `helm`. We use it in manual and Helm approaches.
* [istioctl](https://helm.sh/docs/intro/install/): in the manual approach we use `istioctl` to install Istio.
* [flux](https://fluxcd.io/docs/): FluxCD is a GitOps tool to keep target Kubernetes cluster in sync with the source of configuration in the GitOps directory. The name of FluxCD's CLI tool is `flux`, and we use it in the GitOps approach.

Have them installed on your local environment. Ensure that `kubectl` connects to the cluster correctly. Other CLI tools `helm`, `istioctl` and `flux` all use `kubectl`'s connection profile.