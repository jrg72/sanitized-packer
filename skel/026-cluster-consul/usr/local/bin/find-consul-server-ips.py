#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import boto.ec2
import boto.utils

metadata = boto.utils.get_instance_metadata()

## connect to the region we're launched into
ec2 = boto.ec2.connect_to_region(metadata["placement"]["availability-zone"][:-1])

this_instance_id = metadata["instance-id"]
mac = metadata["mac"]

## find instances in the same VPC tagged with the role of cluster-server
# http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html
instances = ec2.get_only_instances(filters={
    "tag:role": [
        "cluster-server", ## nextgen
        "consul-server", ## old bsd infrastructure
    ],
    "vpc-id":    metadata["network"]["interfaces"]["macs"][mac]["vpc-id"],
})

## return the list of IPs to be used by 'consul join'
## exclude this instance from the list
for i in instances:
    if i.id != this_instance_id:
        print i.private_ip_address
