# -*- yaml -*- (really hcl)

template {
    source = "/etc/consul-template/templates/gocd-agent-env.tmpl"
    destination = "/etc/default/go-agent"
    perms = 0644
    command = "systemctl restart gocd-agent.service"
}

template {
    source = "/etc/consul-template/templates/gocd-agent-autoregister-properties.tmpl"
    destination = "/var/lib/go-agent/config/autoregister.properties"
    perms = 0644
    command = "systemctl restart gocd-agent.service"
}

## bitbucket ssh key
template {
    source = "/etc/consul-template/templates/gocd-agent-ssh-privkey-bitbucket.tmpl"
    destination = "/var/go/.ssh/bitbucket"
    perms = 0400
    command = "chown go:go /var/go/.ssh/bitbucket"
}

## github ssh key
template {
    source = "/etc/consul-template/templates/gocd-agent-ssh-privkey-github.tmpl"
    destination = "/var/go/.ssh/github"
    perms = 0400
    command = "chown go:go /var/go/.ssh/github"
}

## git.bluestatedigital.com ssh key
template {
    source = "/etc/consul-template/templates/gocd-agent-ssh-privkey-bsd.tmpl"
    destination = "/var/go/.ssh/bsd"
    perms = 0400
    command = "chown go:go /var/go/.ssh/bsd"
}
