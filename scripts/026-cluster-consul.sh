#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

CONSUL_VERSION="0.7.0"
CONSUL_TEMPLATE_VERSION="0.16.0"
ENVCONSUL_VERSION="0.6.1"

pushd "$( mktemp -d )"

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./026-cluster-consul

## bind-utils provides "dig", "host", etc
yum install -y bind-utils dnsmasq unzip

## I think this is necessary after installing, but not positive
systemctl enable dnsmasq.service

## create the consul user
## checks can't be executed if the shell's /sbin/nologin, as of CentOS 7.2
useradd --home-dir /var/lib/consul --create-home --system --shell /bin/bash consul

## create consul config directory
mkdir /etc/consul.d
chown consul:consul /etc/consul.d
chmod 740 /etc/consul.d

## set permissions on consul pki files
chown -R consul:consul /etc/pki/consul
chmod 550 /etc/pki/consul
chmod 440 /etc/pki/consul/*


## download, validate, and install consul and the web UI
curl -v -sfSLO https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
curl -v -sfSLO https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_web_ui.zip
curl -v -sfSLO https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS
curl -v -sfSLO https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig
gpg --no-default-keyring --keyring=/tmp/packer-gpg --verify consul_${CONSUL_VERSION}_SHA256SUMS{.sig,}
egrep '(_web_ui\.zip|_linux_amd64\.zip)$' consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c

unzip -q consul_${CONSUL_VERSION}_linux_amd64.zip
mv consul /usr/local/bin/

mkdir -p /usr/local/share/consul/ui
(cd /usr/local/share/consul/ui && unzip -q "${OLDPWD}/consul_${CONSUL_VERSION}_web_ui.zip" )
chown -R consul:consul /usr/local/share/consul

curl -v -sfSLO https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
curl -v -sfSLO https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS
curl -v -sfSLO https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS.sig
gpg --no-default-keyring --keyring=/tmp/packer-gpg --verify consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS{.sig,}
egrep '_linux_amd64\.zip$' consul-template_${CONSUL_TEMPLATE_VERSION}_SHA256SUMS | sha256sum -c

unzip -q consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip
mv consul-template /usr/local/bin/

curl -v -sfSLO https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip
curl -v -sfSLO https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_SHA256SUMS
curl -v -sfSLO https://releases.hashicorp.com/envconsul/${ENVCONSUL_VERSION}/envconsul_${ENVCONSUL_VERSION}_SHA256SUMS.sig
gpg --no-default-keyring --keyring=/tmp/packer-gpg --verify envconsul_${ENVCONSUL_VERSION}_SHA256SUMS{.sig,}
egrep '_linux_amd64\.zip$' envconsul_${ENVCONSUL_VERSION}_SHA256SUMS | sha256sum -c

unzip -q envconsul_${ENVCONSUL_VERSION}_linux_amd64.zip
mv envconsul /usr/local/bin/

## set permissions, since the UIDs in the tarball are different than our own
chown root:root /usr/local/bin/consul /usr/local/bin/consul-template /usr/local/bin/envconsul
chmod 555 /usr/local/bin/consul /usr/local/bin/consul-template /usr/local/bin/envconsul

systemctl enable consul-join.service
systemctl enable consul-leave.service
systemctl enable consul.service
