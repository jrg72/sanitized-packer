# -*- yaml -*- (really hcl)

template {
    source      = "/etc/vault-template/templates/consul-agent.tmpl"
    destination = "/etc/consul.d/creds.json"
    perms       = 0400
    ## create a receipt indicating that the credentials have been written.
    ## used as a guard by consul_gen_acl_token_for_(consul|vault).sh when
    ## bootstrapping the coord cluster.
    command     = "chown consul:consul /etc/consul.d/creds.json && systemctl restart consul; touch /run/consul/vt-creds-created"
}
