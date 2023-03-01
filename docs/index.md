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

To automate Orthanc deployment, we created [Orthweb](https://github.com/digihunch/orthweb) project, a reference implementation for Orthanc on AWS with automation. Further, we introduced this Korthweb project to host Orthanc on Kubernetes. Korthweb provides a reference implementation towards a modern, cloud-native, feature-rich and extensible medical imaging solution, combining the power of Orthanc and Kubernetes.

The Korthweb project comes with three deployment options, with different levels of automation and feature sets. The goal of this project is to automate Orthanc deployment on an established Kubernetes cluster. 

A solid design of Kubernetes cluster sets the foundation for security, reliability and scalability. However, provisioning a Kubernetes cluster itself is beyond the focus of this project. In the `Infrastructure` section, we provide some tools to build a quick Kubernetes cluster for test purposes.

The `Deployment` section discusses the methodologies, the tooling and the three deployment approaches we landed on, with a comparison of the approaches.

The `Validation` section provides a guideline on how to verify the deployment, including how to visit the web portal and send some images in DICOM.

## Project layout

    mkdocs.yml    # The configuration file for documentation
    docs/         # Documentation
    gitops/
        index.md  # The documentation homepage.
        ...       # Other markdown pages, images and other files.
    helm/
    manual/
