log_level                :info
log_location             STDOUT
node_name                'otto'
client_key               '~/.chef/otto.pem'
chef_server_url          'https://ops-chef01.plminternal.com/organizations/plm'
cache_type               'BasicFile'
cache_options( :path => '~/.chef/checksums' )
cookbook_path [ '~/chef/cookbooks' ]
knife[:editor] = "vim"
### PLM cookbook generator:
if defined?(ChefDK)
  chefdk.generator_cookbook "~/Source/chef/plm-skeleton"
  chefdk.generator.license = 'all_rights'
  chefdk.generator.copyright_holder = 'PatientsLikeMe'
  chefdk.generator.email = 'cookbooks@patientslikeme.com'
end
