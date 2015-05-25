log_location     STDOUT
chef_server_url  "https://chef.example.com/organizations/example"
validation_client_name "example-validator"
validation_key '/etc/chef/example-validator.pem'
# Using default node name (fqdn)
trusted_certs_dir "/etc/chef/trusted_certs"
