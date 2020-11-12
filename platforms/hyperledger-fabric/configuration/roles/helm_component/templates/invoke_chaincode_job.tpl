apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: {{ component_name }}
  namespace: {{ namespace }}
  annotations:
    fluxcd.io/automated: "false"
spec:
  releaseName: {{ component_name }}
  chart:
    git: {{ git_url }}
    ref: {{ git_branch }}
    path: {{ charts_dir }}/invoke_chaincode
  values:
    metadata:
      namespace: {{ namespace }}
      network:
        version: {{ network.version }}
      images:
        fabrictools: {{ fabrictools_image }}
        alpineutils: {{ alpine_image }}
    peer:
      name: {{ peer_name }}
      address: {{ peer_address }}
      localmspid: {{ name }}MSP
      loglevel: debug
      tlsstatus: true
    vault:
      role: vault-role
      address: {{ vault.url }}
      authpath: {{ namespace | e }}-auth
      adminsecretprefix: secret/crypto/peerOrganizations/{{ namespace }}/users/admin 
      orderersecretprefix: secret/crypto/peerOrganizations/{{ namespace }}/orderer
      serviceaccountname: vault-auth
      imagesecretname: regcred
      tls: false
    orderer:
      address: {{ participant.ordererAddress }}
    chaincode:
      builder: hyperledger/fabric-ccenv:{{ network.version }}
      name: {{ component_chaincode.name | lower | e }}
      version: {{ component_chaincode.version }}
      invokearguments: {{ component_chaincode.arguments | quote}}
      endorsementpolicies:  {{ component_chaincode.endorsements | quote }}
    channel:
      name: {{ item.channel_name | lower }}
{% if '2.' in network.version %}
    endorsers:
        creator: {{ namespace }}
        name: {% for name in approvers.name %} {{ name }} {% endfor %} 
        corepeeraddress: {% for address in approvers.corepeerAddress %} {{ address }} {% endfor %}
{% endif %}