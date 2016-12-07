#!/usr/bin/env python
# -*- encoding: utf-8 -*-

## outputs ui,say and ui,error to stdout, generates per-builder output for
## easier postmortem debugging.
## generates JSON describing the artifacts created by packer
# {
#     "ami-cluster-base": {
#         "builder_id": "mitchellh.amazonebs",
#         "ami-ids": {
#             "eu-west-1": "ami-958527e6",
#             "us-east-1": "ami-42e9bc28",
#             "us-west-1": "ami-e382e983",
#             "us-west-2": "ami-aef6e9cf",
#         }
#     },
# }

import csv
import sys
import json
import re
import os


class FileIterable(object):
    """iterates over the lines in a file"""
    def __init__(self, ifp):
        super(FileIterable, self).__init__()
        self.ifp = ifp
    
    def next(self):
        line = self.ifp.readline()
        if not line:
            raise StopIteration()

        return line
    
    def __iter__(self):
        return self


def packer_printable(data):
    return data.replace("%!(PACKER_COMMA)", ",").replace(r"\n", "\n").replace(r"\r", "\r")


def main(packer_csv):
    output_dir = os.path.join(os.getcwd(), "work")

    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

    ## maintains state of the artifacts as we process them from the stream.
    ## don't assume that artifact data is output serially.
    ## key is build name
    state = {}
    
    ## map of build name to file object to capture per-build output
    fds = {}
    
    for line in csv.reader(FileIterable(open(packer_csv, "rb", 0))):
        ## if not empty, target is the name of the build

        timestamp, target, p_type = line[:3]
        data = line[3:]
        
        if p_type == "ui":
            msg_type = data[0]
            output = packer_printable(data[1])
            
            if msg_type in ("say", "error"):
                print output
            
            ## find builder name in output, if possible
            match = re.match(r"^((?:--|==)>|\s+) (\S+): (.*)$", output)
            if match:
                prefix, build_name, output = match.groups()
                
                if build_name not in fds:
                    out_fn = os.path.join(output_dir, build_name + ".txt")
                    print "capturing %s output to %s" % (build_name, out_fn)
                    fds[build_name] = open(out_fn, "w")
                
                print >>fds[build_name], prefix + " " + output

        elif p_type == "artifact-count":
            state[target] = [{}] * int(data[0])

        elif p_type == "artifact":
            index, subtype = data[:2]
            subtype_data = data[2:]
            
            artifact = state[target][int(index)]

            if subtype in ("builder-id", "id"):
                artifact[subtype] = packer_printable(subtype_data[0])

            elif subtype == "files-count":
                if int(subtype_data[0]) > 0:
                    artifact["files"] = [""] * int(subtype_data[0])

            elif subtype == "file":
                artifact["files"][int(subtype_data[0])] = packer_printable(subtype_data[1])
    
    result_payload = {}

    for build, artifacts in state.items():
        for artifact in artifacts:
            bid = artifact["builder-id"]

            if bid == "mitchellh.amazonebs":
                result_payload[build] = {
                    "builder_id": bid,
                    "ami-ids": dict([ d.split(":") for d in artifact["id"].split(",") ]),
                }
            
            elif bid == "mitchellh.post-processor.vagrant":
                result_payload[build] = {
                    "builder_id": bid,
                    "boxes": artifact["files"],
                }

    for fd in fds.values():
        fd.close()
    
    with open(os.path.join(output_dir, "artifacts.json"), "w") as ofp:
        json.dump(result_payload, ofp, indent=4)

if __name__  == "__main__":
    main(*sys.argv[1:])
