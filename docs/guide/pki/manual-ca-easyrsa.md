# Manual CA with easyrsa

If you need help creating one, you might find the [easyrsa](https://github.com/OpenVPN/easy-rsa/) package helpful. Use the following to manage an easyrsa-based PKI for OpenVPN...


## Initial Setup

First download the `easyrsa` package.

    $ mkdir easyrsa
    $ wget -qO- "https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.0-rc1/EasyRSA-3.0.0-rc1.tgz" \
      | tar -xzC easyrsa --strip-components 1

Customize a `.envrc` file to store some reusable config values (try [direnv](http://direnv.net/)...

    $ cat > .env << EOF
    export OPENVPN_HOST="vpn.example.com"
    export OPENVPN_PORT=1194
    export EASYRSA_VARS_FILE="vars"
    export EASYRSA_REQ_COUNTRY="US"
    export EASYRSA_REQ_PROVINCE="California"
    export EASYRSA_REQ_CITY="San Francisco"
    export EASYRSA_REQ_ORG="Copyleft Certificate Co"
    export EASYRSA_REQ_OU="My Organizational Unit"
    export EASYRSA_REQ_EMAIL="me@example.net"
    EOF

    $ direnv allow
    direnv: loading .envrc

Initialize your PKI and create the authority...

    $ ( cd easyrsa/ && EASYRSA_PKI=../pki ./easyrsa init-pki )
    $ cd pki
    $ cat ../easyrsa/vars.example \
      | sed -E "s/^#?set_var[[:space:]]+EASYRSA[[:space:]]+.*\$/set_var EASYRSA \"\$PWD\/..\/easyrsa\"/" \
      | sed -E "s/^#?set_var[[:space:]]+EASYRSA_PKI[[:space:]]+.*\$/set_var EASYRSA_PKI \"\$PWD\"/" \
      > vars
    $ ../easyrsa/easyrsa build-ca
      # password will be used whenever you need to sign new certificates
      # common name = openvpn
    $ ../easyrsa/easyrsa gen-crl
    $ ../easyrsa/easyrsa gen-dh
    $ cd ../


## Creating a New Key

When a server or client needs to generate a certificate, you can use a temporary directory and `openssl` to create one.

First create a temporary directory, named after the unique server or client profile name...

    mkdir main-server
    cd main-server

Then create a key and certificate request...

    $ openssl req -new -nodes -days 3650 -newkey rsa:2048 \
      -subj "/C=$EASYRSA_REQ_COUNTRY/ST=$EASYRSA_REQ_PROVINCE/L=$EASYRSA_REQ_CITY/O=$EASYRSA_REQ_ORG/OU=$EASYRSA_REQ_OU/CN=$( basename $PWD )/emailAddress=$EASYRSA_REQ_EMAIL" \
      -out "$( dirname $PWD ).req" \
      -keyout "$( dirname $PWD ).key"

[Sign the certificate](#signing-a-certificate-request). In the case of a server certificate, you may want to retain the private key in your `pki` directory...

    cp "$( dirname $PWD ).key" "$PKI_DIR/private/$( dirname $PWD ).key"

Once signed and delivered for the connection profile, you should delete the temporary directory with the `*.req` and `*.key` files.


## Signing a Certificate Request

The `easyrsa` package can create two types of certificates (client and server) which can only be used for their specific purpose. Assuming you received a certificate signing request file of `certificate.req`, first import it into your `pki` directory...

    $ CN=$( openssl req -in certificate.req -noout -subject | sed -E 's#^.+/CN=([^/]+).*#\1#' )
    $ mv certificate.req "pki/reqs/$CN.req"
    $ cd pki

**Server Certificate**

    $ ../easyrsa/easyrsa sign server "$CN"

**Client Certificate**

    $ ../easyrsa/easyrsa sign client "$CN"

Once a certificate is signed, you can provide it back to the requester.

    $ cat "pki/issued/$CN.crt"


# Server Configuration

Once you have a PKI setup and a server key-pair configured, you can use the file data for the `openvpn` job properties.

 * `tls_key_pair.ca` is `./pki/ca.crt`
 * `tls_key_pair.certificate` is `./pki/issued/main-server.crt`
 * `tls_key_pair.private_key` is `./pki/private/main-server.key`
 * `tls_crl` is `./pki/crl.pem`
 * `dh_pem` is `./pki/dh.pem`


# Client Configuration


Once a client has had their key-pair signed, they will want to include it in the base OpenVPN profile configuration:

 * `<key>` is the client private key
 * `<cert>` is the signed certificate

Typically, the base OpenVPN profile configuration should be provided by the OpenVPN server operator. It will look something like the following.

    client
    dev tun
    proto tcp
    remote $OPENVPN_HOST $OPENVPN_PORT
    comp-lzo
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    mute-replay-warnings
    remote-cert-tls server
    verb 3
    mute 20
    tls-client
    <ca>
    # OpenVPN server CA
    </ca>

Once the user appends their private key to the profile, they can use file with their [OpenVPN client]({{< relref "../client/end-user-software.md" >}}).

   $ openvpn --config client.ovpn
