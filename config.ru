require './zimbra_rest_app.rb'

####### Configurarion Options ############################

ZimbraRestAPI.zimbra_soap_url = ENV['zimbra_soap_url']
ZimbraRestAPI.zimbra_admin_user = ENV['zimbra_admin_user']
ZimbraRestAPI.zimbra_admin_password = ENV['zimbra_admin_password']

####### END CONFIGURATION ############################

###### DONT TOUCH FROM HERE ######################

puts '------------------------------------------------'
puts 'Starting server with the following configuration'
puts "SOAP URL: #{ZimbraRestAPI.zimbra_soap_url}"
puts "ADMIN USER: #{ZimbraRestAPI.zimbra_admin_user}"
puts "------------------------------------------------\n"

run ZimbraRestApp
