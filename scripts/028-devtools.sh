#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

yum install epel-release
yum install python-pip
yum groupinstall "Development Tools"
yum install python-devel
pip install jq
