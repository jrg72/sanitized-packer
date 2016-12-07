#!/bin/bash

set -x -e -u -o pipefail

## http://elrepo.org/tiki/kernel-ml
## > The kernel-ml packages are built from the sources available from the
## > "mainline stable" branch of The Linux Kernel Archives (external link). The
## > kernel configuration is based upon the default RHEL-7 configuration with
## > added functionality enabled as appropriate. The packages are intentionally
## > named kernel-ml so as not to conflict with the RHEL-7 kernels and, as such,
## > they may be installed and updated alongside the regular kernel.

rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -ivh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

yum --enablerepo=elrepo-kernel -y install kernel-ml

echo "removing the old kernel"
rpm -e --verbose kernel

echo "rebooting..."
reboot

echo "sleeping for 2 minutes to keep Packer on its toes"
sleep 120
