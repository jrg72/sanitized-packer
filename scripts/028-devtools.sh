#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

yum localinstall -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -q epel-release ## yum localinstall doesn't fail if package install fails

yum install -y python-pip
yum install -y zlib-devel
yum groupinstall -y "Development Tools"
yum install -y python-devel
pip install jq
