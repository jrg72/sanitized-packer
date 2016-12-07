#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

RKT_VERSION="1.16.0"

pushd "$( mktemp -d )"

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./033-rkt-host

## download, verify, and install rkt
curl -sfSLO https://github.com/coreos/rkt/releases/download/v${RKT_VERSION}/rkt-v${RKT_VERSION}.tar.gz
curl -sfSLO https://github.com/coreos/rkt/releases/download/v${RKT_VERSION}/rkt-v${RKT_VERSION}.tar.gz.asc
gpg --no-default-keyring --keyring=/tmp/packer-gpg --verify rkt-v${RKT_VERSION}.tar.gz{.asc,}

tar -xzf rkt-v${RKT_VERSION}.tar.gz --strip-components=1

mv rkt /usr/bin/
mv init/systemd/tmpfiles.d/* /usr/lib/tmpfiles.d/
mv init/systemd/rkt-* /usr/lib/systemd/system/
mv bash_completion/rkt.bash /etc/bash_completion.d/rkt

gzip -9 manpages/*.1
mv manpages/*.1.gz /usr/share/man/man1/

mkdir -p /usr/lib/rkt/stage1-images
mv ./*.aci /usr/lib/rkt/stage1-images/

./scripts/setup-data-dir.sh

systemctl enable \
    rkt-gc.service \
    rkt-gc.timer \
    rkt-metadata.service \
    rkt-metadata.socket
