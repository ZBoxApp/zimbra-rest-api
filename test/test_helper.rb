ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'minitest/reporters' # requires the gem
require 'rack/test'

require File.expand_path '../../zimbra_rest_app.rb', __FILE__

# spec-like progress
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

ZimbraRestApi.zimbra_soap_url = ENV['zimbra_soap_url']
ZimbraRestApi.zimbra_admin_user = ENV['zimbra_admin_user']
ZimbraRestApi.zimbra_admin_password = ENV['zimbra_admin_password']
ZimbraRestApi.authenticate!
