require 'json'
require 'uri'
require 'uuid'
require 'zimbra'
require 'pp'
require_relative 'helpers'
require_relative 'zimbra_rest_api/zimbra_object'
require_relative 'zimbra_rest_api/utils'
require_relative 'models/zimbra_base'
require_relative 'models/domain'
require_relative 'models/account'
require_relative 'models/distribution_list'

# Doc placeholder
module ZimbraRestApi
  class << self
    attr_accessor :zimbra_admin_user, :zimbra_admin_password
    attr_reader :zimbra_soap_url

    def authenticate!
      Zimbra.admin_api_url = zimbra_soap_url
      Zimbra.login(zimbra_admin_user, zimbra_admin_password)
    end

    def zimbra_soap_url=(url)
      uri = URI.parse(url)
      fail URI::InvalidURIError unless uri.is_a?(URI::HTTP)
      @zimbra_soap_url = url
    end

  end
end
