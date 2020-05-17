#!/bin/bash

set -eu

fail () { echo "FAILURE: $1" >&2 ; exit 1 ; }

cd repo

. /usr/local/bin/start-bosh -o $PWD/ci/tasks/integration-test/bosh-ops.yml

source /tmp/local-bosh/director/env

if [ -e stemcell/*.tgz ]; then
  bosh upload-stemcell stemcell/*.tgz
  os=$( tar -Oxzf stemcell/*.tgz stemcell.MF | grep '^operating_system: ' | awk '{ print $2 }' )
else
  bosh upload-stemcell \
    --name=bosh-warden-boshlite-ubuntu-trusty-go_agent \
    --version=3586.25 \
    --sha1=b9a44806dc1bb99b0d11d7413742f3619139da0b \
    https://s3.amazonaws.com/bosh-core-stemcells/warden/bosh-stemcell-3586.25-warden-boshlite-ubuntu-trusty-go_agent.tgz
  os=ubuntu-trusty
fi

export BOSH_DEPLOYMENT=integration-test

bosh -n deploy \
  --var os="$os" \
  --var repo_dir="$PWD" \
  --vars-store=/tmp/deployment-vars.yml \
  ci/tasks/integration-test/deployment.yml


#
# role1 -> role2
#

bosh ssh role1/0 '
  set -e
  sudo ping -c 5 192.168.206.1 | sudo tee -a /var/vcap/sys/log/openvpn-client/stdout.log
  sleep 5
  sudo /var/vcap/bosh/bin/monit stop openvpn-client
  sleep 5
'

mkdir -p role1-logs

bosh scp role1/0:/var/vcap/sys/log/openvpn-client/stdout.log role1-logs/client-stdout.log
bosh scp role1/0:/var/vcap/sys/log/openvpn/stdout.log role1-logs/stdout.log

if ! grep -q "Initialization Sequence Completed" role1-logs/client-stdout.log* ; then
  fail "Client failed to connect to server"
elif ! grep -q "/sbin/ifconfig tun1 192.168.206.2 netmask 255.255.255.0" role1-logs/client-stdout.log* ; then
  fail "Client failed to establish tunnel correctly"
elif ! grep -q "Initialization Sequence Completed" role1-logs/client-stdout.log* ; then
  fail "Client did not complete initialization sequence"
elif ! grep -q "64 bytes from 192.168.206.1" role1-logs/client-stdout.log* ; then
  fail "Client was unable to ping the remote gateway"
elif ! grep -q "process exiting" role1-logs/client-stdout.log* ; then
  fail "Client did not exit cleanly"
fi


#
# role2 -> role1
#

bosh ssh role2/0 '
  set -e
  sudo ping -c 5 192.168.202.1 | sudo tee -a /var/vcap/sys/log/openvpn-client/stdout.log
  sleep 5
  sudo /var/vcap/bosh/bin/monit stop openvpn-client
  sleep 5
'

mkdir -p role2-logs

bosh scp role2/0:/var/vcap/sys/log/openvpn-client/stdout.log role2-logs/client-stdout.log
bosh scp role2/0:/var/vcap/sys/log/openvpn/stdout.log role2-logs/stdout.log

if ! grep -q "Initialization Sequence Completed" role2-logs/client-stdout.log* ; then
  fail "Client failed to connect to server"
elif ! grep -q "/sbin/ifconfig tun1 192.168.202.2 netmask 255.255.255.0" role2-logs/client-stdout.log* ; then
  fail "Client failed to establish tunnel correctly"
elif ! grep -q "Initialization Sequence Completed" role2-logs/client-stdout.log* ; then
  fail "Client did not complete initialization sequence"
elif ! grep -q "64 bytes from 192.168.202.1" role2-logs/client-stdout.log* ; then
  fail "Client was unable to ping the remote gateway"
elif ! grep -q "process exiting" role2-logs/client-stdout.log* ; then
  fail "Client did not exit cleanly"
fi


#
# multi-client -> role1
# multi-client -> role2
#

bosh ssh multi-client/0 '
  set -e
  sudo ping -c 5 192.168.202.1 | sudo tee -a /var/vcap/sys/log/openvpn-clients/client-role1.stdout.log
  sudo ping -c 5 192.168.206.1 | sudo tee -a /var/vcap/sys/log/openvpn-clients/client-role2.stdout.log
  sleep 5
  sudo /var/vcap/bosh/bin/monit stop openvpn-client-role1
  sudo /var/vcap/bosh/bin/monit stop openvpn-client-role2
  sleep 5
'

mkdir -p multi-client-logs

bosh scp multi-client/0:/var/vcap/sys/log/openvpn-clients/client-role1.stdout.log multi-client-logs/client-role1.stdout.log
bosh scp multi-client/0:/var/vcap/sys/log/openvpn-clients/client-role2.stdout.log multi-client-logs/client-role2.stdout.log

if ! grep -q "Initialization Sequence Completed" multi-client-logs/client-role1.stdout.log ; then
  fail "Client role1 failed to connect to server"
elif ! grep -q "/sbin/ifconfig tun2 192.168.202.3 netmask 255.255.255.0" multi-client-logs/client-role1.stdout.log ; then
  fail "Client role1 failed to establish tunnel correctly"
elif ! grep -q "Initialization Sequence Completed" multi-client-logs/client-role1.stdout.log ; then
  fail "Client role1 did not complete initialization sequence"
elif ! grep -q "64 bytes from 192.168.202.1" multi-client-logs/client-role1.stdout.log ; then
  fail "Client role1 was unable to ping the remote gateway"
elif ! grep -q "process exiting" multi-client-logs/client-role1.stdout.log ; then
  fail "Client role1 did not exit cleanly"
fi

if ! grep -q "Initialization Sequence Completed" multi-client-logs/client-role2.stdout.log ; then
  fail "Client role2 failed to connect to server"
elif ! grep -q "/sbin/ifconfig tun3 192.168.206.3 netmask 255.255.255.0" multi-client-logs/client-role2.stdout.log ; then
  fail "Client role2 failed to establish tunnel correctly"
elif ! grep -q "Initialization Sequence Completed" multi-client-logs/client-role2.stdout.log ; then
  fail "Client role2 did not complete initialization sequence"
elif ! grep -q "64 bytes from 192.168.206.1" multi-client-logs/client-role2.stdout.log ; then
  fail "Client role2 was unable to ping the remote gateway"
elif ! grep -q "process exiting" multi-client-logs/client-role2.stdout.log ; then
  fail "Client role2 did not exit cleanly"
fi


#
# teardown
#

bosh -n delete-deployment


#
# stop-bosh
#

bosh -n clean-up --all

bosh delete-env "/tmp/local-bosh/director/bosh-director.yml" \
  --vars-store="/tmp/local-bosh/director/creds.yml" \
  --state="/tmp/local-bosh/director/state.json"
