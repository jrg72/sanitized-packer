## resources

https://github.com/smerrill/packer-templates/blob/master/centos-6.4-x86_64-netboot/

## custom cloud-init modules

all enabled by default.

### consul

Generates `/etc/consul.conf` as JSON directly from the YAML body.  Sets `GOMAXPROCS` based on the output of `nproc`.

```yaml
consul:
    datacenter:         us-west-1_aws_hack0
    server:             true
    rejoin_after_leave: true
    bootstrap_expect:   3
    data_dir:           "/var/lib/consul"
    enable_syslog:      true
```

### systemd-reload

Runs in the "final" cloud-init phase; makes sure systemd drop-in config files take affect.
