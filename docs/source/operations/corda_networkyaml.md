# Configuration file specification: R3 Corda
A network.yaml file is the base configuration file for setting up a Corda DLT network. This file contains all the information related to the infrastructure and network specifications. Here is the structure of it.
![](./../_static/TopLevelClass-Corda.png)

Before setting up a Corda DLT/Blockchain network, this file needs to be updated with the required specifications.
A sample configuration file is provide in the repo path:  
`platforms/r3-corda/configuration/samples/network-cordav2.yaml`  

A json-schema definition is provided in `platforms/network-schema.json` to assist with semantic validations and lints. You can use your favorite yaml lint plugin compatible with json-schema specification, like `redhat.vscode-yaml` for VSCode. You need to adjust the directive in template located in the first line based on your actual build directory:

`# yaml-language-server: $schema=../platforms/network-schema.json`


The configurations are grouped in the following sections for better understanding.

* type

* version

* frontend

* env

* docker

* network_services

* organizations

Here is the snapshot from the sample configuration file

![](./../_static/NetworkYamlCorda1.png)

The sections in the sample configuration file are  

`type` defines the platform choice like corda/fabric/quorum. Use `corda` for **Corda Opensource** and `corda-enterprise` for **Corda Enterprise**.

`version` defines the version of platform being used, here in example the Corda version is 4.0, the corda version 4.7 is supported by latest release. Please note only 4.4 above is supported for **Corda Enterprise**.

`frontend` is a flag which defines if frontend is enabled for nodes or not. Its value can only be enabled/disabled. This is only applicable if the sample Supplychain App is being installed.

`env` section contains the environment type and additional (other than 8443) Ambassador port configuration. Value for proxy field under this section has to be 'ambassador' as 'haproxy' has not been implemented for Corda.

The snapshot of the `env` section with example values is below
```yaml
  env:
    type: "env-type"                # tag for the environment. Important to run multiple flux on single cluster
    proxy: ambassador               # value has to be 'ambassador' as 'haproxy' has not been implemented for Corda
    ambassadorPorts:                # Any additional Ambassador ports can be given here, this is valid only if proxy='ambassador'
      portRange:              # For a range of ports 
        from: 15010 
        to: 15043
    # ports: 15020,15021      # For specific ports
    loadBalancerSourceRanges: # (Optional) Default value is '0.0.0.0/0', this value can be changed to any other IP adres or list (comma-separated without spaces) of IP adresses, this is valid only if proxy='ambassador'
    retry_count: 20                 # Retry count for the checks
    external_dns: enabled           # Should be enabled if using external-dns for automatic route configuration
```
The fields under `env` section are 

| Field      | Description                                 |
|------------|---------------------------------------------|
| type       | Environment type. Can be like dev/test/prod.|
| proxy      | Choice of the Cluster Ingress controller. Currently supports `ambassador` only as `haproxy` has not been implemented for Corda |
| ambassadorPorts   | Any additional Ambassador ports can be given here. This is only valid if `proxy: ambassador`     |
| loadBalancerSourceRanges | (Optional) Restrict inbound access to a single or list of IP adresses for the public Ambassador ports to enhance BAF network security. This is only valid if `proxy: ambassador`.  |
| retry_count       | Retry count for the checks. Use a large number if your kubernetes cluster is slow. |
| external_dns       | If the cluster has the external DNS service, this has to be set `enabled` so that the hosted zone is automatically updated. |


`docker` section contains the credentials of the repository where all the required images are built and stored.

For Opensource Corda, the required instructions are found [here](../architectureref/corda.html#docker-images).

For **Corda Enterprise**, all Docker images has to be built and stored in a private Docker registry before running the Ansible playbooks. The required instructions are found [here](../architectureref/corda-ent.html#docker-images).

The snapshot of the `docker` section with example values is below
```yaml
  # Docker registry details where images are stored. This will be used to create k8s secrets
  # Please ensure all required images are built and stored in this registry. 
  docker:
    url: "<url>"
    username: "<username>"
    password: "<password>"
```
The fields under `docker` section are

| Field      | Description                                 |
|------------|---------------------------------------------|
| url        | Docker registry url. Must be private registry for **Corda Enterprise**    | 
| username   | Username credential required for login      |
| password   | Password credential required for login      |

---
**NOTE:** Please follow [these instructions](../operations/configure_prerequisites.html#docker) to build and store the docker images before running the Ansible playbooks.

---

The snapshot of the `network_services` section with example values is below
```yaml
  # Remote connection information for doorman/idman and networkmap (will be blank or removed for hosting organization)
  network_services:
    - service:
      name: doorman
      type: doorman
      uri: https://doorman.test.corda.blockchaincloudpoc.com:8443
      certificate: home_dir/platforms/r3-corda/configuration/build/corda/doorman/tls/ambassador.crt
      crlissuer_subject: "CN=Corda TLS CRL Authority,OU=Corda UAT,O=R3 HoldCo LLC,L=New York,C=US"
    - service:
      name: networkmap
      type: networkmap
      uri: https://networkmap.test.corda.blockchaincloudpoc.com:8443
      certificate: home_dir/platforms/r3-corda/configuration/build/corda/networkmap/tls/ambassador.crt
      truststore: home_dir/platforms/r3-corda-ent/configuration/build/networkroottruststore.jks #Certificate should be encoded in base64 format
      truststore_pass: rootpassword
```
The `network_services` section contains a list of doorman/networkmap which is exposed to the network. Each `service` has the following fields:

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| type        | For Corda, `networkmap` and `doorman` (`idman` for **Corda Enterprise**) are the only valid type of network_services.    |
| name | Only for **Corda Enterprise**. Name of the idman/networkmap service. |
| uri         | Doorman/IDman/Networkmap external URL. This should be reachable from all nodes.     | 
| certificate | Absolute path to the public certificates for Doorman/IDman and Networkmap.             |
| crlissuer_subject | Only for **Corda Enterprise Idman**. Subject of the CRL Issuer.|
| truststore | Only for **Corda Enterprise Networkmap**. Absolute path to the base64 encoded networkroot truststore.|
| truststore_pass | Only for **Corda Enterprise Networkmap**. Truststore password |


The `organizations` section allows specification of one or many organizations that will be connecting to a network. If an organization is also hosting the root of the network (e.g. doorman, membership service, etc), then these services should be listed in this section as well.
In the sample example the 1st Organisation is hosting the root of the network, so the services doorman, nms and notary are listed under the 1st organization's service.

The snapshot of an organization field with sample values is below
```yaml
    - organization:
      name: manufacturer
      country: CH
      state: Zurich
      location: Zurich
      subject: "O=Manufacturer,OU=Manufacturer,L=Zurich,C=CH"
      type: node
      external_url_suffix: test.corda.blockchaincloudpoc.com
      cloud_provider: aws # Options: aws, azure, gcp
```

Each organization under the `organizations` section has the following fields. 

| Field                                    | Description                                 |
|------------------------------------------|-----------------------------------------------------|
| name                                        | Name of the organization                                                                                         |
| country                                     | Country of the organization                                                                                      |
| state                                       | State of the organization                                                                                        |
| location                                    |  Location of the organization                                                                                    |
| subject                                     | Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| subordinate_ca_subject | Only for **Corda Enterprise**. Subordinate CA Subject for the CENM.|
| type                                        | This field can be doorman-nms-notary/node/cenm              |
| version | Defines the CENM version. Only for **Corda Enterprise**, must be `1.5` |
| external_url_suffix                         | Public url suffix of the cluster. This is the configured path for the Ambassador Service on the DNS provider.|
| cloud_provider                              | Cloud provider of the Kubernetes cluster for this organization. This field can be aws, azure or gcp |
| aws                                         | When the organization cluster is on AWS |
| k8s                                         | Kubernetes cluster deployment variables.|
| vault                                       | Contains Hashicorp Vault server address and root-token in the example |
| gitops                                      | Git Repo details which will be used by GitOps/Flux. |
| Firewall                                    | Only for **Corda Enterprise Networkmap**. Contains firewall options and credentials |
| cordapps (optional)                         | Cordapps Repo details which will be used to store/fetch cordapps jar |
| services                                    | Contains list of services which could be peers/doorman/nms/notary/idman/signer | 


For the aws and k8s field the snapshot with sample values is below
```yaml
      aws:
        access_key: "<aws_access_key>"    # AWS Access key, only used when cloud_provider=aws
        secret_key: "<aws_secret>"        # AWS Secret key, only used when cloud_provider=aws
  
      # Kubernetes cluster deployment variables.
      k8s:        
        region: "<k8s_region>"
        context: "<cluster_context>"
        config_file: "<path_to_k8s_config_file>"
```

The `aws` field under each organisation contains: (This will be ignored if cloud_provider is not 'aws')

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| access_key                              | AWS Access key  |
| secret_key                              | AWS Secret key  |

The `k8s` field under each organisation contains

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| context                                 | Context/Name of the cluster where the organization entities should be deployed                                   |
| config_file                             | Path to the kubernetes cluster configuration file                                                                |

For gitops fields the snapshot from the sample configuration file with the example values is below
```yaml
      # Git Repo details which will be used by GitOps/Flux.
      gitops:
        git_protocol: "https" # Option for git over https or ssh
        git_url: "https://github.com/<username>/blockchain-automation-framework.git" # Gitops htpps or ssh url for flux value files
        branch: "<branch_name>"                                                  # Git branch where release is being made
        release_dir: "platforms/r3-corda/releases/dev" # Relative Path in the Git repo for flux sync per environment. 
        chart_source: "platforms/r3-corda/charts"      # Relative Path where the Helm charts are stored in Git repo
        git_repo: "github.com/<username>/blockchain-automation-framework.git"
        username: "<username>"          # Git Service user who has rights to check-in in all branches
        password: "<password>"          # Git Server user password/personal token (Optional for ssh; Required for https)
        email: "<git_email>"              # Email to use in git config
        private_key: "<path to gitops private key>" # Path to private key (Optional for https; Required for ssh)
```

The `gitops` field under each organization contains

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| git_protocol | Option for git over https or ssh. Can be `https` or `ssh` |
| git_url                              | SSH or HTTPs url of the repository where flux should be synced                                                            |
| branch                               | Branch of the repository where the Helm Charts and value files are stored                                        |
| release_dir                          | Relative path where flux should sync files                                                                       |
| chart_source                         | Relative path where the helm charts are stored                                                                   |
| git_repo                         | Gitops git repo URL https URL for git push like "github.com/hyperledger-labs/blockchain-automation-framework.git"             |
| username                             | Username which has access rights to read/write on repository                                                     |
| password                             | Password of the user which has access rights to read/write on repository (Optional for ssh; Required for https)  |
| email                                | Email of the user to be used in git config                                                                       |
| private_key                          | Path to the private key file which has write-access to the git repo (Optional for https; Required for ssh)       |   


The `credentials` field under each organization contains

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| keystore    | Contains passwords for keystores                         |
| truststore  | Contains passwords for truststores                       |
| ssl         | Contains passwords for ssl keystores                     |

For organization as type `cenm` the credential block looks like
```yaml
      credentials:
        keystore:
          keystore: cordacadevpass #notary keystore password
          idman: password #idman keystore password
          networkmap: password #networkmap keystore password
          subordinateca: password #subordinateCA keystore password
          rootca: password # rootCA keystore password
          tlscrlsigner: password #tls-crl-signer keystore password
        truststore:
          truststore: trustpass #notary truststore password
          rootca: password #network root truststore password
          ssl: password #corda ssl truststore password
        ssl:
          networkmap: password #ssl networkmap keystore password
          idman: password #ssl idman keystore password
          signer: password #ssl signer keystore password
          root: password #ssl root keystore password
```
For organization as type `node` the credential section is under peers section and looks like
```yaml
          credentials:
            truststore: trustpass #node truststore password
            keystore: cordacadevpass #node keystore password
```

For cordapps fields the snapshot from the sample configuration file with the example values is below: This has not been implented for **Corda Enterprise**.
```yaml
      # Cordapps Repository details (optional use if cordapps jar are store in a repository)
      cordapps:
        jars: 
        - jar:
            # e.g https://alm.accenture.com/nexus/repository/AccentureBlockchainFulcrum_Release/com/supplychain/bcc/cordapp-supply-chain/0.1/cordapp-supply-chain-0.1.jar
            url: 
        - jar:
            # e.g https://alm.accenture.com/nexus/repository/AccentureBlockchainFulcrum_Release/com/supplychain/bcc/cordapp-contracts-states/0.1/cordapp-contracts-states-0.1.jar
            url: 
        username: "cordapps_repository_username"
        password: "cordapps_repository_password"
```

The `cordapps` optional field under each organization contains

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| jars        | Contains list of jars with jar URL that needs to fetched and put into organisation nodes    |
| username                             | Cordapps Repository username |
| password                             | Cordapps Repository password |

For **Corda Enterprise**, following additional fields have been added under each `organisation`.
```yaml
      firewall:
        enabled: true       # true if firewall components are to be deployed
        subject: "CN=Test Firewall CA Certificate, OU=HQ, O=HoldCo LLC, L=New York, C=US"
        credentials:
            firewallca: firewallcapassword
            float: floatpassword
            bridge: bridgepassword
```

The `Firewall` field under each node type organization contains; valid only for enterprise corda

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| enabled     | true/false for enabling firewall (external bridge and float)   |
| subject     | Certificate Subject for firewall, format at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| credentials | Contains credentials for bridge and float                |

The services field for each organization under `organizations` section of Corda contains list of `services` which could be doorman/idman/nms/notary/peers for opensource, and additionally idman/networkmap/signer/bridge/float for **Corda Enterprise**.

The snapshot of doorman service with example values is below
```yaml
      services:
        doorman:
          name: doormanskar
          subject: "CN=Corda Doorman CA,OU=DLT,O=DLT,L=Berlin,C=DE"
          db_subject: "/C=US/ST=California/L=San Francisco/O=My Company Ltd/OU=DBA/CN=mongoDB"
          type: doorman
          ports:
            servicePort: 8080
            targetPort: 8080
          tls: "on"
```

The fields under `doorman` service are 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name            | Name for the Doorman service                                                                                 |
| subject                    | Certificate Subject for Doorman service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| db_subject                 | Certificate subject for mongodb database of doorman
| type                       | Service type must be `doorman`                                                                             |
| ports.servicePort          | HTTP port number where doorman service is accessible                                       |
| ports.targetPort           | HTTP target port number of the doorman docker-container                                       |
| tls                        | On/off based on whether we want TLS on/off for doorman 

The snapshot of nms service example values is below
```yaml
        nms:
          name: networkmapskar
          subject: "CN=Network Map,OU=FRA,O=FRA,L=Berlin,C=DE"
          db_subject: "/C=US/ST=California/L=San Francisco/O=My Company Ltd/OU=DBA/CN=mongoDB"
          type: networkmap
          ports:
            servicePort: 8080
            targetPort: 8080
          tls: "on"  
```
The fields under `nms` service are

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name                | Name of the NetworkMap service                     |
| subject      | Certificate Subject for NetworkMap service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| db_subject              | Certificate subject for mongodb database of nms.
| type                    | Service type must be `networkmap`    |
| ports.servicePort       | HTTP port number where NetworkMap service is accessible                                       |
| ports.targetPort        | HTTP target port number of the NetworkMap docker-container                                  |
| tls                     | On/off based on whether we want TLS on/off for nms

For **Corda Enterprise**, following services must be added to CENM Support.

The snapshot of idman service with example values is below
```yaml
      services:
        idman:
          name: idman
          subject: "CN=Test Identity Manager Service Certificate, OU=HQ, O=HoldCo LLC, L=New York, C=US"
          crlissuer_subject: "CN=Corda TLS CRL Authority,OU=Corda UAT,O=R3 HoldCo LLC,L=New York,C=US"
          type: cenm-idman
          port: 10000
```

The fields under `idman` service are 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name            | Name for the IDman service                                                                                 |
| subject                    | Certificate Subject for Idman service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| crlissuer_subject                 | Certificate subject for CRL Issuer service |
| type                       | Service type must be `cenm-idman`                                                                             |
| port          | HTTP port number where idman service is accessible internally                                     |

The snapshot of networkmap service with example values is below
```yaml
      services:
        networkmap:
          name: networkmap
          subject: "CN=Test Network Map Service Certificate, OU=HQ, O=HoldCo LLC, L=New York, C=US"
          type: cenm-networkmap
          ports:
            servicePort: 10000
            targetPort: 10000
```

The fields under `networkmap` service are 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name            | Name for the Networkmap service                                                                                 |
| subject                    | Certificate Subject for Networkmap service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| type                       | Service type must be `cenm-networkmap`                                                                             |
| ports.servicePort          | HTTP port number where networkmap service is accessible internally                                       |
| ports.targetPort           | HTTP target port number of the networkmap docker-container                                       |

The snapshot of signer service with example values is below
```yaml
      services:
        signer:
          name: signer
          subject: "CN=Test Subordinate CA Certificate, OU=HQ, O=HoldCo LLC, L=New York, C=US"
          type: cenm-signer
          ports:
            servicePort: 8080
            targetPort: 8080 
```

The fields under `signer` service are 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name            | Name for the Signer service                                                                                 |
| subject                    | Certificate Subject for Signer service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| type                       | Service type must be `cenm-signer`                                                                             |
| ports.servicePort          | HTTP port number where signer service is accessible                                       |
| ports.targetPort           | HTTP target port number of the signer docker-container                                       |

The snapshot of notary service with example values is below
```yaml
        # Currently only supporting a single notary cluster, but may want to expand in the future
        notary:
          name: notary1
          subject: "O=Notary,OU=Notary,L=London,C=GB"
          serviceName: "O=Notary Service,OU=Notary,L=London,C=GB" # available for Corda 4.7 onwards to support HA Notary
          type: notary          
          p2p:
            port: 10002
            targetPort: 10002
            ambassador: 15010       #Port for ambassador service (must be from env.ambassadorPorts above)
          rpc:
            port: 10003
            targetPort: 10003
          rpcadmin:
            port: 10005
            targetPort: 10005
          dbtcp:
            port: 9101
            targetPort: 1521
          dbweb:             
            port: 8080
            targetPort: 81
```
The fields under `notary` service are 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name                     | Name of the notary service   |
| subject                   | Certificate Subject for notary node. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| serviceName            | Certificate Subject for notary service applicable from Corda 4.7 onwards. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| type                      | Service type must be `notary`  |
| validating | Only for **Corda Enterprise Notary**. Determines if Notary is validating or non-validating. Use `true` or `false` |
| emailAddress | Only for **Corda Enterprise Notary**. Email address in the notary conf. |
| p2p.port                  | Corda Notary P2P port. Used for communication between the notary and nodes of same network|
| p2p.targetport            | P2P Port where notary service is running. |
| p2p.ambassadorport        | Port where notary service is exposed via Ambassador|
| rpc.port                  | Corda Notary RPC port. Used for communication between the notary and nodes of same network|
| rpc.targetport            | RPC Port where notary services is running.|
| rpcadmin.port             | Corda Notary Rpcadmin port. Used for RPC admin binding|
| dbtcp.port                | Corda Notary DbTcp port. Used to expose database to other services                                         |
| dbtcp.targetPort          | Corda Notary DbTcp target port. Port where the database services are running                               |
| dbweb.port                | Corda Notary dbweb port. Used to expose dbweb to other services                                            |
| dbweb.targetPort          | Corda Notary dbweb target port. Port where the dbweb services are running                                  |

The snapshot of float service with example values is below
```yaml
      float: 
        name: float
        subject: "CN=Test Float Certificate, OU=HQ, O=HoldCo LLC, L=New York, C=US"
        external_url_suffix: test.cordafloat.blockchaincloudpoc.com
        cloud_provider: aws   # Options: aws, azure, gcp
        aws:
          access_key: "aws_access_key"        # AWS Access key, only used when cloud_provider=aws
          secret_key: "aws_secret_key"        # AWS Secret key, only used when cloud_provider=aws
        k8s:
          context: "float_cluster_context"
          config_file: "float_cluster_config"
        vault:
          url: "float_vault_addr"
          root_token: "float_vault_root_token"
        gitops:
          git_url: "https://github.com/<username>/blockchain-automation-framework.git"         # Gitops https or ssh url for flux value files 
          branch: "develop"           # Git branch where release is being made
          release_dir: "platforms/r3-corda-ent/releases/float" # Relative Path in the Git repo for flux sync per environment. 
          chart_source: "platforms/r3-corda-ent/charts"     # Relative Path where the Helm charts are stored in Git repo
          git_repo: "github.com/<username>/blockchain-automation-framework.git"   # Gitops git repository URL for git push 
          username: "git_username"          # Git Service user who has rights to check-in in all branches
          password: "git_access_token"          # Git Server user password/access token (Optional for ssh; Required for https)
          email: "git_email"                # Email to use in git config
          private_key: "path_to_private_key"          # Path to private key file which has write-access to the git repo (Optional for https; Required for ssh)
        ports:
          p2p_port: 40000
          tunnelport: 39999
          ambassador_tunnel_port: 15021
          ambassador_p2p_port: 15020
```

The fields under `float` service are below. Valid for corda enterprise only.

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name            | Name for the float service                                                                                 |
| subject                    | Certificate Subject for Float service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |
| external_url_suffix                         | Public url suffix of the cluster. This is the configured path for the Ambassador Service on the DNS provider.|
| cloud_provider                              | Cloud provider of the Kubernetes cluster for this organization. This field can be aws, azure or gcp |
| aws                                         | When the organization cluster is on AWS |
| k8s                                         | Kubernetes cluster deployment variables.|
| vault                                       | Contains Hashicorp Vault server address and root-token in the example |
| gitops                                      | Git Repo details which will be used by GitOps/Flux. |
| ports.p2p_port                              | Peer to peer service port                           |
| ports.tunnel_port                           | Tunnel port for tunnel between float and bridge service |
| port.ambassador_tunnel_port                 | Ambassador port for tunnel between float and bridge service |
| gitops                                      | Ambassador port Peer to peer  |

The fields under `bridge` service are below. Valid for corda enterprise only. 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name            | Name for the bridge service                                                                                 |
| subject                    | Certificate Subject for bridge service. Subject format can be referred at [OpenSSL Subject](https://www.openssl.org/docs/man1.0.2/man1/openssl-req.html) |

The snapshot of peer service with example values is below
```yaml
      # The participating nodes are named as peers 
      services:
        peers:
        - peer:
          name: manufacturerskar
          subject: "O=Manufacturer,OU=Manufacturer,L=47.38/8.54/Zurich,C=CH"
          type: node
          p2p:
            port: 10002
            targetPort: 10002
            ambassador: 15010       #Port for ambassador service (must be from env.ambassadorPorts above)
          rpc:
            port: 10003
            targetPort: 10003
          rpcadmin:
            port: 10005
            targetPort: 10005
          dbtcp:
            port: 9101
            targetPort: 1521
          dbweb:             
            port: 8080
            targetPort: 81
          springboot:             # This is for the springboot server
            targetPort: 20001
            port: 20001 
          expressapi:             # This is for the express api server
            targetPort: 3000
            port: 3000
```
The fields under each `peer` service are 

| Field       | Description                                              |
|-------------|----------------------------------------------------------|
| name                          | Name of the Corda Node                                                                                           |
| type                          | Service type must be `node` |
| subject                       | The node legal name subject. |
| auth                          | Vault auth of the corda Node                                                                                     |
| p2p.port                      | Corda Node P2P port.Used for communication between the nodes  of same network                                    |
| rpc.port                      | Corda Node RPC port. Used for communication between the nodes of different network                               |
| rpcadmin.port                 | Corda Node Rpcadmin port. Used for RPC admin binding                                                             |
| dbtcp.port                    | Corda Node DbTcp port. Used to expose database to other services                                           |
| dbtcp.targetPort              | Corda Node DbTcp target port. Port where the database services are running                               |
| dbweb.port                    | Corda Node dbweb port. Used to expose dbweb to other services                                                    |
| dbweb.targetPort              | Corda Node dbweb target port. Port where the dbweb services are running                                        |
| springboot.port               | Springboot server port. Used to expose springboot to other    services                                           |
| springboot.targetPort         | Springboot server  target port. Port where the springboot services are running                               |
| expressapi.port               | Expressapi port. Used to expose expressapi to other services                                                     |
| expressapi.targetPort         | Expressapi target port. Port where the expressapi services are running                                        |
