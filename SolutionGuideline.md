# Production Solution Guideline

The GitOps approach consists of database and storage configurations for demo. This page covers the limitations of this demo setup, considrations for scalability and options for production setup.

## Limitation with database in the demo setup
Although [Orthanc](https://book.orthanc-server.com/faq/orthanc-storage.html?highlight=database) supports both MYSQL and PostgreSQL plugins, in Korthweb I choose to focus on PostgreSQL, simply to contain scope. In Orthanc configuration, EnableIndex for PostgreSQL is set to true.

In the demo setup, I used Helm chart to configure PostgreSQL service, in its own namespace in the same cluster. While it automates the configuration, the following day-2 issues will surface:

1. Lack of immutability: any workload deployed by Helm is not being continuously monitored and reconciled for configuration drifts. An operator-based approach (e.g. CrunchyData PGO) can help.
2. Not using storage class: the database uses default storage class, without considering the availability, durability and performance.
3. Database management: DIY hosting database service on Kubernetes requires skills on database and Kubernetes platforms. Depending on your team's skill level, motivation, report structure, etc, it is oftentimes not an economical path. Refer to blog post [Hosting database on Kubernetes](https://www.digihunch.com/2022/05/hosting-database-on-kubernetes/)

## Limitation with storage in the demo setup
In Orthanc configuration for PostgreSQL, EnableStorage is set to true. Therefore Orthanc stores pixels in PostgreSQL database. However, the pixel data are unstructured and not recommended to be stored in a relational database. It is recommended to set EnableStorage under PostgreSQL to false for production use.

## Production database setup
For production setup, you will need a database service with its own layer of stability. Day-2 operation involves managing the underlying storage, expanding the database, administering replication, backup, patching, security, etc. The easy path is using managed database by the cloud provider, such as Azure database for PostgreSQL, Amazon RDS or GCP Cloud SQL for PostgreSQL. 

## Production storage setup
The Osimis image includes Orthanc [S3 plugin](https://book.orthanc-server.com/plugins/object-storage.html), which allows to store images as objects. Alternatively, you can store images on file systems mounted to Pods.

With S3 plugin, you can either use Amazon S3, or any self-hosted S3-compatible object storage. [MinIO](https://min.io/) is a good choice. 

For file storage, you will need to configure storage classes and persistent volumes. In each cloud platform, there is some pre-built storage classes to consider. 

Another option is to consider an SDS (software defined storage) layer. For SDS-based storage solution, you may use a proprietary solution such as Portworx, or an open-source self-hosted alternative such as Ceph by Rook. 