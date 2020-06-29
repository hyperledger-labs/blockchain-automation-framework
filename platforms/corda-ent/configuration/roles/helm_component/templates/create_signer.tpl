apiVersion: flux.weave.works/v1beta1
kind: HelmRelease
metadata:
  name: {{ services.signer.name }}
  annotations:
    flux.weave.works/automated: "false"
  namespace: {{ component_ns }}
spec:
  releaseName: {{ services.signer.name }}
  chart:
    path: {{ org.gitops.chart_source }}/{{ chart }}
    git: {{ org.gitops.git_ssh }}
    ref: {{ org.gitops.branch }}
  values:
    nodeName: {{ services.signer.name }}
    metadata:
      namespace: {{component_ns }}
    replicas: 1
    image:
      imagePullSecret: regcred
      initContainerName: {{ network.docker.url }}/alpine-utils:1.0
    storage:
      name: {{ org.cloud_provider }}storageclass
    dockerImageSigner:
      name: corda/enterprise-signer
      tag: 1.2-zulu-openjdk8u242
      pullPolicy: Always
    acceptLicense: YES
    vault:
      address: {{ vault.url }}
      role: vault-role
      authpath: {{ component_auth }}
      serviceaccountname: vault-auth
      certsecretprefix: {{ services.signer.name }}/certs
    healthcheck:
      readinesscheckinterval: 10
      readinessthreshold: 15
    serviceSsh:
      port: {{ services.signer.ports.servicePort }}
      targetPort: {{ services.signer.ports.targetPort }}
      type: ClusterIP
    service:
      type: ClusterIP
      port: 20003
    shell:
      user: signer
      password: signerP

    idmanPublicIP: {{ services.signer.name }}.{{ item.external_url_suffix }}
    idmanPort: 10000

    serviceLocations:
      identityManager:
        host: idman-internal
        port: 5052
      networkMap:
        host: nmap-internal
        port: 5050
      revocation:
        port: 5053
    signers:
      CSR:
        schedule:
        interval: 1m
      CRL:
        schedule:
        interval: 1d
      NetworkMap:
        schedule:
        interval: 1m
      NetworkParameters:
        schedule:
        interval: 1m
    cordaJarMx: 1
    healthCheckNodePort: 0
    jarPath: bin
    configPath: etc