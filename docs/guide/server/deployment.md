# Server Deployment

The repository includes manifests for basic deployment configurations inside the [`deployment`](../../../deployment) directory for quickly creating a standalone OpenVPN server and client configuration. This is a great way to get started, but you should familiarize yourself with OpenVPN and key management practices before using it with a team. For more advanced needs, consider deploying this release with BOSH director and CredHub.


## Prerequisites

Make sure you have several tools installed...

 * `bosh` - from [bosh.io](http://bosh.io/docs/cli-v2#install)
 * `ruby` - used by `bosh` to generate server configuration files
 * `openvpn` - for [connecting]({{< relref "../client/end-user-software.md" >}}) from your workstation


## Configuration

Start a YAML configuration file named `openvpn-creds.yml` which will contain simple key/value settings for the server. This will contain credentials, so be sure to manage and store the file securely. To start, decide a few core settings and update the configuration file using the following as a template.

```yaml
# the starting address of the VPN network assigned to clients
vpn_network: 192.168.250.0

# the VPN network mask (as both IP and bits)
vpn_network_mask: 255.255.255.0
vpn_network_mask_bits: 24

# IaaS/LAN internal network
lan_network: 10.10.250.0
lan_network_mask: 255.255.255.0
lan_network_mask_bits: 24
lan_gateway: 10.10.250.1
lan_ip: 10.10.250.9

# IaaS/WAN public IP address
wan_ip: 123.123.123.123
```


### Optional Features

There are several `with-*.yml` files which can be used to change some behaviors of the server. To use, include them in the later `create-env` command, and be sure to add documented settings to the configuration file.


#### Gateway Redirection

If you want to force clients to redirect all their traffic through the VPN server, include the `-o with-gateway-redirection.yml` option.


#### Log Forwarding

If you want to forward system and OpenVPN logs to a syslog server, include the `-o with-log-forwarding.yml` option. Be sure to add a few more settings to `openvpn-creds.yml`...

```yaml
# the syslog server host and port
syslog_address: logs12345.papertrailapp.com
syslog_port: 12345

# the protocol to use (tcp, udp, or relp)
syslog_transport: tcp

# whether to use TLS
syslog_tls_enabled: true
```


#### SSH Access

If you want SSH access with the user `openvpn`, include the `-o with-ssh.yml` option. To use an existing public key, set `ssh.public_key` in `openvpn-creds.yml`...

```yaml
ssh:
  public_key: ssh-rsa ....
```

If you do not set `ssh`, a key will be generated during deployment. You can reference the generated private key by running `bosh int openvpn-creds.yml --path=/ssh/private_key`.


## Infrastructure

Identify which IaaS you will be deploying to (e.g. Amazon Web Services, Google, vSphere). You should create a firewall in your IaaS to restrict access to the server.

The following ingress ports are used...

 * `22/tcp` - SSH access (only required to enable SSH access, or for some IaaSes during provisioning)
 * `1194/tcp` - OpenVPN
 * `6868/tcp` - BOSH management service (only required during provisioning)

You may want to restrict egress traffic, depending on your requirements.


### Amazon Web Services (`aws`)

AWS requires the additional settings that you should add to `openvpn-creds.yml` using the following template...

```yaml
# region and availability zone to deploy to
region: us-east-1
availability_zone: us-east-1d

# VPC subnet to deploy to
subnet_id: subnet-a1b2c3d4

# a specific, private IP address for the VM
internal_ip: 10.10.250.9

# security group IDs to apply to the VM
default_security_groups: [sg-a1b2c3d4]

# an already-registered key pair name, and path to the ssh private key
bootstrap_ssh_key_name: default
bootstrap_ssh_key_path: ~/.ssh/id_rsa
```

While provisioning to AWS, SSH access will be required. Ensure port `22/tcp` is open, although it can be disabled once provisioning is finished.

Ensure the standard `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables are set. When running the `create-env` command, you'll need to append the following arguments to the command...

    -o init-aws.yml -v access_key_id="$AWS_ACCESS_KEY_ID" -v secret_access_key="$AWS_SECRET_ACCESS_KEY"


### Google Cloud Platform (`google`)

GCP requires the additional settings that you should add to `openvpn-creds.yml` using the following template...

```yaml
# the project to use
project_id: openvpn-test

# the zone to deploy to
zone: us-east1-b

# the network and subnetwork to deploy to
network: default
subnetwork: default

# zero or more tags to apply to the VM
tags: [openvpn]
```

Ensure you have a service account file. When running the `create-env` command, you'll need to append the following arguments to the command...

    -o init-google.yml --var-file gcp_credentials_json=~/.config/gcloud/application_default_credentials.json


## Deploy

Once everything has been configured, run the full `create-env` command. Be sure to add IaaS and feature-specific arguments to the command, as necessary.

    bosh create-env openvpn.yml --vars-store openvpn-creds.yml # add extra arguments

For example, if using AWS with log forwarding and gateway redirection, the full command would look like...

    bosh create-env openvpn.yml --vars-store openvpn-creds.yml \
      -o init-aws.yml -v access_key_id="$AWS_ACCESS_KEY_ID" -v secret_access_key="$AWS_SECRET_ACCESS_KEY" \
      -o with-syslog-forwarding.yml \
      -o with-gateway-redirection.yml

You may want to document the full command in a simple shell script to avoid reconstructing the command in the future.

After the command has completed, there will be an `openvpn-state.json` file - be sure to retain it in addition to your `openvpn-creds.yml`.


## Client Setup

After the server is running, you can generate an OpenVPN connection profile for [a client]({{< relref "../client/end-user-software.md" >}})...

    bosh interpolate --vars-store openvpn-client-creds.yml -l openvpn-creds.yml --path=/profile openvpn-client.yml > openvpn-client.ovpn

And then use the profile to connect...

    openvpn --config openvpn-client.ovpn
