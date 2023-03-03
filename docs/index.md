# Korthweb - Orthanc on Kubernetes

<a href="https://www.orthanc-server.com/"><img style="float" align="right" src="assets/images/orthanc_logo.png"></a>

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
[Orthanc](https://www.orthanc-server.com/) is an open-source application suite to ingest, store, distribute and display medical images. [Osimis](https://www.osimis.io/) releases Orthanc in [Docker images](https://hub.docker.com/r/osimis/orthanc). Deployment of Orthanc can be complex. 

To automate Orthanc deployment, Digi Hunch created [Orthweb](https://github.com/digihunch/orthweb) project, a reference Orthanc deployment on AWS. Further, we started this Korthweb project to host Orthanc on Kubernetes. Korthweb provides reference deployment paradigms towards a modern, cloud-native and extensible medical imaging solution, combining the power of Orthanc and Kubernetes.

The Korthweb project comes with three deployment options, with different automation levels and feature sets. The goal is to deploy Orthanc workload on an established Kubernetes cluster. 

A solid design of Kubernetes cluster sets the foundation for security, reliability and scalability. However, cluster provisioning itself is beyond the focus of this project. In the `Infrastructure` section, we provide some tools to build a quick Kubernetes cluster for test purposes.

The `Deployment` section discusses the methodologies, the tooling and the three deployment approaches, with a comparison.

The `Validation` section provides guidelines on how to verify the funtionality after each deployment approach, including produce and send images in DICOM.

## Get started
If you do not have a K8s cluster, review the `Infrastructure` section and spend the time to create a working cluster. Ensure that you can connect to the cluster with kubectl and your identity has admin permission.

If you can connect to your K8s cluster with kubectl, assuming the user has admin permission, skip to `Deployment` section for the next step. 

## Project Layout
    gitops/               # Artifacts for FluxCD to consume
        application/      # Templates for orthanc workload
        dependency/       # Templates for dependency services
        infrastructure/   # Templates for cluster wide services
        observability/    # Templates for observability addons
        fluxcd/           # Flux working directory
            flux-system/  # Flux system directory maintained by Flux controller 
            ...           # Top-level Kustomization definitions
    helm/
        orthanc/          # Helm chart directory for Helm approach
    manual/               # Artifacts for manual approach
    docs/                 # Documentation pages
    mkdocs.yml            # Documentation configuration
