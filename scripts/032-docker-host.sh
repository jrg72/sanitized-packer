#!/bin/bash

## sets up docker and a storage pool to be used by docker.
## an EBS volume at /dev/xvdf is REQUIRED!

exec 0<&- # close stdin

set -e -u -o pipefail

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./032-docker-host

yum install -y docker-engine-1.7.1-1.el7.centos

systemctl enable \
    docker.service \
    docker.socket \
    docker-storage-pool.service \
    'dev-mapper-docker\x2dpool0.device'
