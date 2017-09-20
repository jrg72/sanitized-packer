#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

VAGRANT_VERSION="1.9.1"

pushd "$( mktemp -d )"

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./030-gocd-vagrant

## bind-utils provides "dig", "host", etc
yum install -y 'https://opensource.enda.eu/packages/http-parser-2.7.1-3.el7.x86_64.rpm' # otherwise nodejs is broken in Cent 7.3 seriously wtf
yum install -y bind-utils dnsmasq unzip
yum install -y openssl-devel readline-devel zlib-devel postgresql-devel qt5-qtwebkit qt-devel postgresql libpqxx-devel nodejs qt5-qtwebkit-devel xorg-x11-server-Xvfb

## download, validate, and install vagrant
curl -v -sfSLO https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.rpm
curl -v -sfSLO https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_SHA256SUMS
curl -v -sfSLO https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_SHA256SUMS.sig
gpg --no-default-keyring --keyring=/tmp/packer-gpg --verify vagrant_${VAGRANT_VERSION}_SHA256SUMS{.sig,}
egrep '(_x86_64\.rpm)$' vagrant_${VAGRANT_VERSION}_SHA256SUMS | sha256sum -c

rpm -ivh vagrant_${VAGRANT_VERSION}_x86_64.rpm

#/usr/local/rbenv/shims/gem install thor:'< 0.19.2' kitchen-ec2
