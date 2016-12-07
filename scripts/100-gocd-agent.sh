#!/usr/bin/env bash

## this causes 'git clone' to fail with "Error reading command stream"
# exec 0<&- # close stdin

set -e -u -o pipefail

pushd "$( mktemp -d )"

yum install -y java-1.8.0-openjdk-headless.x86_64

yum localinstall -y https://download.go.cd/binaries/16.2.1-3027/rpm/go-agent-16.2.1-3027.noarch.rpm
rpm -q go-agent ## yum localinstall doesn't fail if package install fails

## add the go user to the rkt and docker groups. this'll allow the go user to
## interact with docker.  rkt is for future use.
usermod -a -G rkt go
usermod -a -G docker go

## we're managing this with systemd, now
chkconfig go-agent off
rm -f /etc/init.d/go-agent

yum localinstall -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -q epel-release ## yum localinstall doesn't fail if package install fails

yum install -y git golang python-pip
pip install awscli==1.9.12

git clone --verbose --progress --branch panic-drawing-progress-bar https://github.com/blalor/acbuild.git
pushd acbuild
./build
cp bin/acbuild /usr/local/bin/
popd

## unpack skel for this module
tar -xz \
    --preserve-permissions \
    --no-same-owner \
    --strip-components=2 \
    -f /tmp/packer-skel.tgz \
    -C / \
    ./100-gocd-agent

## retrieve host keys for SSH servers we'll be connecting to
## super-long timeout because bitbucket is show as shit
ssh-keyscan \
    -T 60 \
    github.com bitbucket.org git.bluestatedigital.com \
    >| /etc/ssh/ssh_known_hosts

## ensure we got them all
if [ "$( wc -l /etc/ssh/ssh_known_hosts | cut -d ' ' -f 1 )" -ne 3 ]; then
    echo "expected 3 host keys"
    cat /etc/ssh/ssh_known_hosts
    exit 1
fi

## this needs to exist, or consul-template will create it and make it owned by
## root, which breaks the agent because it can't write another file there.
## looks like it already exists, tho I can't figure out how it's created…
mkdir /var/lib/go-agent/config || true
chown -R go:go /var/lib/go-agent/config

## set ownership and permissions on files in go home
find ~go/.ssh -type f -exec chmod 400 {} \;
chmod 700 ~go/.ssh
chown -R go:go ~go
