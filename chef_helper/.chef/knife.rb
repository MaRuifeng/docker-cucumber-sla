# See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options

current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "cuke_test"
client_key               "#{current_dir}/cuke_test.pem"
validation_client_name   "cuke_test-validator"
validation_key           "#{current_dir}/cuke_test-validator.pem"
chef_server_url          "https://#{ENV['CHEF_HOSTNAME']}:9443/organizations/cuke_test"
cookbook_path            ["#{current_dir}/../cookbooks"]
