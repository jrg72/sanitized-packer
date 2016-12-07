#!/bin/bash

set -e -u

join_method="${1}"

if [ "${join_method}" = "srv" ]; then
    ## read's return code is 1 if no data found
    read -r -a peer_ips < <(
        dig +search +noall +answer SRV _consul._tcp | \
            sed -e 's/\.$//g' | \
            awk '{printf("%s:%d\n", $8, $7)}' \
    ) || true
elif [ "${join_method}" = "ec2-tags" ]; then
    mapfile -t peer_ips < <( /usr/local/bin/find-consul-server-ips.py )
fi

if [ ${#peer_ips[@]} -eq 0 ]; then
    echo "no peer ips found with method ${join_method}"
    exit 1
else
    echo "joining to ${peer_ips[*]}"
    
    consul join "${peer_ips[@]}"

    if jq -e '.server == true' /etc/consul.conf >/dev/null ; then
        consul join -wan "${peer_ips[@]}"
        
        ## centralbooking writes out the list of servers in the coordinator
        ## cluster so that servers can join to them.  this list is static so it
        ## could become out of date, but as long as it works once, we should be
        ## fine.
        cb_wan_peers_path="/var/lib/centralbooking/consul_wan_servers.json"
        if [ -e ${cb_wan_peers_path} ]; then
            mapfile -t peer_ips < <( jq -r .[] ${cb_wan_peers_path} )
            consul join -wan "${peer_ips[@]}" || true
        fi
    fi
fi
