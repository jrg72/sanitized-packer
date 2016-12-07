# -*- yaml -*- (really hcl)

## primary vault config.

vault {
    # token and address provided in separate file from centralbooking config
    renew_token = true

    ssl {
        enabled = true
    }
}
