#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

if [ "${PACKER_BUILDER_TYPE}" != "virtualbox-iso" ]; then
    echo "skipping for builder ${PACKER_BUILDER_TYPE}"
    exit 0
fi

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./020-vagrant

date > /etc/vagrant_box_build_time

/usr/sbin/useradd vagrant
echo vagrant | passwd --stdin vagrant

# Installing vagrant keys
VAG_SSH="/home/vagrant/.ssh"

mkdir -pm 700 ${VAG_SSH}

curl -sfSL -o ${VAG_SSH}/authorized_keys 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub'

chmod 0600 ${VAG_SSH}/authorized_keys
chown -R vagrant:vagrant ${VAG_SSH}
