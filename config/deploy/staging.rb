# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server "34.201.61.180", user: "rental-listing-aggregator", roles: %w{app db web}

set :branch, 'develop'

set :rvm_custom_path, '/usr/share/rvm'
set :rvm_ruby_version, '2.3.8'
