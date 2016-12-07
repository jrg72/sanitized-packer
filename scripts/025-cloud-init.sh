#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./025-cloud-init

## need these for the etcd health check
yum install -y python-dateutil pytz

