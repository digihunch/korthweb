
# Korthweb - Orthanc on Kubernetes

<a href="https://www.orthanc-server.com/"><img style="float" align="right" src="docs/assets/images/orthanc_logo.png"></a>

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

## Introduction
Korthweb provides three approaches to deploy [Orthanc](https://www.orthanc-server.com/) on Kubernetes. Orthanc is an open-source application to ingest, store, display and distribute medical images. Korthweb focues on the deployment. It is a sister project of [Orthweb](https://github.com/digihunch/orthweb), an deployment automation project for Orthanc on AWS. 

To deploy Orthanc (stateless app + database) on Kubernetes, and to securely host DICOM and web workloads, we have incorporated the following configurations:

* Ingress (Istio or Traefik) TLS termination on HTTP and TCP ports
* Use Cert Manager to provision self-signed certificate
* Traffic routing with Istio (Gateway, Virtual Serivce)
* Istio Installation (using Helm charts or Istioctl)
* Security with Istio (Peer Authentication/mTLS, Authorization Policy)
* Deploy observability addons (Prometheus, Grafana) for Istio
* Use bitnami Helm chart to deploy PostgreSQL
* Build your own Helm Chart to deploy Orthanc
* GitOps with FluxCD for Continuous Deployment

## Documentation
The [Korthweb documentation](https://digihunch.github.io/korthweb/) includes a step-by-step guide for each deployment approach.
