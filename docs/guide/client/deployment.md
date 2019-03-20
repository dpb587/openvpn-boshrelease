# Client Deployment

The `openvpn-client` job requires a [link](https://bosh.io/docs/links.html) named `openvpn` which describes the connection to the server. The `openvpn` job implicitly provides the correct link. If you have advanced client configuration or a raw OpenVPN profile, use the `openvpn-clients` job.


## Cross-Deployment Links

Here's an example of consuming a [cross-deployment](https://bosh.io/docs/links.html#cross-deployment) link...

```yaml
instance_groups:
- name: vpn
  jobs:
  - name: openvpn-client
    release: openvpn
    consumes:
      server:
        from: openvpn
        deployment: aws-infra-vpn
```


## Manual Link

For scenarios where the OpenVPN server is not provided by BOSH, you can manually configure the link...

```yaml
instance_groups:
- name: vpn
  jobs:
  - name: openvpn-client
    release: openvpn
    consumes:
      server:
        instances:
        - address: infra-vpn.aws-use1.prod.acme.local
        properties:
          protocol: tcp
          port: 1194
          cipher: AES-256-CBC
          keysize: 256
          tls_server:
            ca: |
              -----BEGIN CERTIFICATE-----
              ...
              -----END CERTIFICATE-----
    properties:
      tls_client:
        certificate: |
          -----BEGIN CERTIFICATE-----
          ...
          -----END CERTIFICATE-----
        private_key: |
          -----BEGIN RSA PRIVATE KEY-----
          ...
          -----END RSA PRIVATE KEY-----
```


## Multiple Clients

For scenarios where a VM needs to connect to multiple OpenVPN servers (or you want to use raw configuration)...

```yaml
instance_groups:
- name: vpn
  jobs:
  - name: openvpn-clients
    release: openvpn
    properties:
      clients:
      - name: aws-use1
        config: |
          remote vpn.aws-us-east-1.staging-snowstorm.internal.example.com 1194 tcp
          ...snip...
          <cert>
          ...
          </cert>
          <key>
          ...
          </key>
      - name: aws-usw2
        config: |
          remote vpn.aws-us-west-1.staging-snowstorm.internal.example.com 1194 tcp
          ...snip...
          <cert>
          ...
          </cert>
          <key>
          ...
          </key>
```
