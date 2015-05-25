# Provisioning Agnostic chef-client install and bootstrap

** node will use it's default FQDN for the node name unless we provide node name **

## the following are needed for the chef-install
1. the trusted_cert from chef server at /var/opt/opscode/nginx/ca/chef-server.example.com.crt needs to be in /etc/chef/trusted_certs on the node
2. the validator.pem for the Chef Organization on the Chef Server needs to be in /etc/chef/ on the node
3. node must have /etc/chef/client.rb with the following
  1. the url of the Chef server
  2. validation key name 'example-validator'
  3. validation key path '/etc/chef/example-validator.pem'
4. DNS for the Chef server FQDN or the Chef server url in /etc/hosts of the node
5. The environment set must exist on the Chef server

## Install command
`sudo sh chef-full.sh CHEF_INSTALL_URL CHEF_VERSION ENVIRONMENT`

#### The CHEF_INSTALL_URL can be changed to use internal installer with internally hosted version.


## Usage

### Clone this repo into /etc/chef on a node


`sudo sh chef-full.sh https://chef.io/chef/install.sh 12.3.0-1 dev`
