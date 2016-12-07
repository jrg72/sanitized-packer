#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

ETCD_VERSION="2.0.12"

pushd "$( mktemp -d )"

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./027-cluster-etcd

## create the etcd user
## (effectively) no skel, because etcd bitches about the dotfiles
useradd \
    --home-dir /var/lib/etcd \
    --create-home \
    --skel /dev/null \
    --system \
    --shell /sbin/nologin \
    etcd

## directory for etcd config files
mkdir --mode=0750 /etc/sysconfig/etcd
chown etcd:etcd /etc/sysconfig/etcd

## add consul user to etcd group, for access to consul acl token used by etcd-
## config.py (invoked by etcd) and etcd-reconcile-members.py (invoked by consul)
usermod --append --groups etcd consul

## download, verify, and install etcd2
curl -sfSLO https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz.gpg
gpg --no-default-keyring --keyring=/tmp/packer-gpg --output etcd-v${ETCD_VERSION}-linux-amd64.tar.gz{,.gpg}
tar \
    -xz \
    -f etcd-v${ETCD_VERSION}-linux-amd64.tar.gz \
    --strip-components=1 \
    -C /usr/local/bin \
    etcd-v${ETCD_VERSION}-linux-amd64/etcd \
    etcd-v${ETCD_VERSION}-linux-amd64/etcdctl

chown root:root /usr/local/bin/etcd{,ctl}

systemctl enable etcd.service
systemctl enable etcd-config.service
systemctl enable etcd-config-clean.service
