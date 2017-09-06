#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

yum install -y python-pip
yum install -y zlib-devel
yum groupinstall -y "Development Tools"
yum install -y python-devel
pip install jq
