#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

pushd "$( mktemp -d )"

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./031-gocd-minion

## bind-utils provides "dig", "host", etc
yum install -y bind-utils dnsmasq unzip git

