#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

## update CAs that may have been added
## https://www.happyassassin.net/2015/01/14/trusting-additional-cas-in-fedora-rhel-centos-dont-append-to-etcpkitlscertsca-bundle-crt-or-etcpkitlscert-pem/
## http://kb.kerio.com/product/kerio-connect/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html
update-ca-trust extract

## remove fstab entries created by cloud-init; these may not exist on instances
## created from this image.
sed -i -e /comment=cloudconfig/d /etc/fstab

## compress rotated log files
sed -i -e 's/^#compress/compress/' /etc/logrotate.conf

## set system clock to hardware clock.  I think this might solve the problem I
## saw where the filesystem superblocks were like a day ahead of the real time
## after creating a new VirtualBox image.
date

## at one point did not work in EC2.  Now it does. Either way, this is best-
## effort.
hwclock -s || true

date

## remove everything under /var/lib/cloud to force cloud-init to re-run
if [ -d /var/lib/cloud ]; then
    find /var/lib/cloud -depth -mindepth 1 -maxdepth 1 -exec rm -vrf {} \; || echo "find exited with ${?}"
fi

## also remove ec2-user
## bah!  can't do this, or subsequent provisioning steps will fail
#getent passwd ec2-user && /usr/sbin/userdel -f -r ec2-user

## set perms on sudoers files
chown root:root /etc/sudoers.d/*
chmod 440 /etc/sudoers.d/*

rm -rf /tmp/*
yum -y clean all

## remove stuff that identifies the host
# https://ifireball.wordpress.com/2015/01/02/creating-rhel7-deployment-templates/
rm -f /etc/hostname
>| /etc/machine-id

[ -x /sbin/dracut ] && /sbin/dracut --no-hostonly --force

## display disk usage
df -h
