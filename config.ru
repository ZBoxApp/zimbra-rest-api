require 'bundler'
Bundler.setup
require 'zimbra_rest_api'

####### Configurarion Options ############################

ZimbraRestApi.zimbra_soap_url = ENV['zimbra_soap_url']
ZimbraRestApi.zimbra_admin_user = ENV['zimbra_admin_user']
ZimbraRestApi.zimbra_admin_password = ENV['zimbra_admin_password']
#ZimbraRestApi.api_id = "12345678"


ZimbraRestApi::Account.zimbra_attrs_to_load = ENV['zimbra_account_attrs'].to_s.split(',')
ZimbraRestApi::Domain.zimbra_attrs_to_load = ENV['zimbra_domain_attrs'].to_s.split(',')
ZimbraRestApi::DistributionList.zimbra_attrs_to_load = ENV['zimbra_dl_attrs'].to_s.split(',')

####### END CONFIGURATION ############################

###### DONT TOUCH FROM HERE ######################

puts '------------------------------------------------'
puts 'Starting server with the following configuration'
puts "SOAP URL: #{ZimbraRestApi.zimbra_soap_url}"
puts "ADMIN USER: #{ZimbraRestApi.zimbra_admin_user}"
puts "------------------------------------------------\n"

run ZimbraRestApi::App
