# Security of Korthweb solution

While Korthweb is a demo project, we take security seriously. We look at security from the perspecives of the network infrastructure, cluster and the workload.

## Network infrastructure security
Network infrastructure design is beyond the scope of this project. It is usually the networking or cloud engineering team of an organization to ensure the security and compliance of their networking foundation.

## Cluster Security
As discussed, K8s cluster design is also beyond the scope of this project. It is usually the platform team to ensure the security configuration of Kubernetes cluster. Refer to [OWASP Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html), and [CIS benchmark](https://www.cisecurity.org/benchmark/kubernetes) for more details.

## Workload Security
Korthweb deployment follows best practices to ensure workload security. Take the GitOps apporach as an example:

1. Both DICOM and web traffic are encrypted in TLS. The deployment process creates [self-signed certificate](https://www.digihunch.com/2022/01/creating-self-signed-x509-certificate/). The GitOps and manual approaches use Cert Manager. The Helm approach use Helm's built-in cryptographic functions.
2. Connections between Orthanc Pods and PostgreSQL are encrypted with mTLS, provided by Istio service mesh.
3. Istio's Peer Authentication applies mTLS for any service-to-service traffic. Refer to the architecture section for how Istio can enhance the security setup.
4. The workload for the two tenants are seperated logically with their own namespaces.