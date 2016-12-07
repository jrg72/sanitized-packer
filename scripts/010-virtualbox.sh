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
    ./010-virtualbox

## fucking VirtualBox's DNS and CentOS don't play nicely together
# shellcheck disable=SC1004
sed -i -e '1i\
RES_OPTIONS="single-request-reopen"' /etc/sysconfig/network-scripts/ifcfg-eth0

## this works on centos6 and 7
service network restart

## don't do DNS lookups for ssh when logging in
sed -i -e 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

kernel="kernel"
yum_args=""
if rpm -q kernel-ml ; then
    kernel="kernel-ml"
    yum_args="--enablerepo=elrepo-kernel"
fi

## build deps for vbox guest additions
yum -y ${yum_args} install \
    gcc \
    ${kernel}-devel \
    ${kernel}-headers \
    dkms \
    make \
    bzip2 \
    perl \
    patch \
    binutils

## install guest additions; at least 4.3.14 required
vbox_ver=$( cat /root/.vbox_version )
vbox_comp_ver=$( echo "${vbox_ver}" | awk -F. '{ print (($1 * 10000) + ($2 * 100) + $3) }' )

if [ "${vbox_comp_ver}" -lt 40314 ]; then
    echo "vbox version too old; have ${vbox_ver}, need >= 4.3.14"
    exit 1
fi

iso="/root/VBoxGuestAdditions_${vbox_ver}.iso"

mkdir -p /mnt
mount -o loop "${iso}" /mnt

/mnt/VBoxLinuxAdditions.run || {
    echo "oh, hey, VBoxGuestAdditions failed to install, exited with ${?}."
    echo "fuck you, Oracle."
}

## cleanup
umount /mnt
rm -rf "${iso}"
