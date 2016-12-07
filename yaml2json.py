#!/usr/bin/env python

import sys
import yaml
import json

json.dump(yaml.load(open(sys.argv[1])), sys.stdout, indent=4)
