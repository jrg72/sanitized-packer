#!/bin/bash

exec 0<&- # close stdin

set -e -u -x

NOMAD_VERSION="0.4.1"

pushd "$( mktemp -d )"

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./035-nomad

## download and install nomad
curl -sfSLO https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip
curl -sfSLO https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS
curl -sfSLO https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_SHA256SUMS.sig
gpg --no-default-keyring --keyring=/tmp/packer-gpg --verify nomad_${NOMAD_VERSION}_SHA256SUMS{.sig,}
egrep '_linux_amd64\.zip$' nomad_${NOMAD_VERSION}_SHA256SUMS | sha256sum -c

unzip nomad_${NOMAD_VERSION}_linux_amd64.zip -d /usr/local/bin

groupadd -r nomad
chown root:nomad /usr/local/bin/nomad

mkdir /var/lib/nomad
chown root:nomad /var/lib/nomad
chmod 3770 /var/lib/nomad # drwxrws--T

systemctl enable nomad.service
