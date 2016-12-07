#!/bin/bash

exec 0<&- # close stdin

set -e -u -o pipefail

pushd "$( mktemp -d )"

tar -xz \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    ./006-import-gpg-keys

## coreos, eventually
## https://github.com/coreos/rkt/issues/971

gpg="gpg --no-default-keyring --keyring=/tmp/packer-gpg"
for x in *; do
    $gpg --import < "${x}"
done
