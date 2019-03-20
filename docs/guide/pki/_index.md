# Public Key Infrastructure

One of most common authentication strategies for OpenVPN is certificates through a [PKI](http://en.wikipedia.org/wiki/Public_key_infrastructure). With this approach, each client has a private key and a certificate which has been signed by a certificate authority that the OpenVPN server trusts.

Below are several strategies for managing certificates.


## Manually-managed CA

With a manually-managed CA the operations team handles all certificate verification and signing operations for your servers and users. Some example processes using the [easyrsa package](https://github.com/OpenVPN/easy-rsa/) are [documented here]([manually-managed CA]({{< relref "manual-ca-easyrsa.md" >}})).


## CredHub

If you are using [Cloud Foundry CredHub](https://docs.cloudfoundry.org/credhub/) you can use BOSH to generate server and client certificates. The sample deployment manifests utilize this strategy.


## ssoca

Built as an alternative to manually-provisioned and long-lived certificates, `ssoca` was created to bridge external authentication and certificate signing. Visit the [repository](https://github.com/dpb587/ssoca) and its [documentation](https://dpb587.github.io/ssoca/) to learn more.
