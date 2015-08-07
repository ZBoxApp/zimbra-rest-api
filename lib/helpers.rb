module ZimbraRestApi
  module Helpers

    def resource_index(resource, params = {})
      object = resource.camelize(true).constantize
      json object.all(params)
    end

    def resource_show(resource, id)
      object = resource.camelize(true).constantize
      result = object.find(id)
      return json(result) if result
      status 404
    end

    def resource_create(resource, params)
      object = resource.camelize(true).constantize
      begin
        json object.create(params)
      rescue Zimbra::HandsoapErrors::SOAPFault => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_update(resource, id, params)
      object = resource.camelize(true).constantize
      result = object.find(id)
      return status 404 if result.nil?
      begin
        json result.update_attributes(params)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_delete(resource, id)
      object = resource.camelize(true).constantize
      result = object.find(id)
      return status 404 if result.nil?
      begin
        result.delete
        status 200
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_add_grant(resource, id, params)
      object = resource.camelize(true).constantize
      result = object.find(id)
      return status 404 if result.nil?
      begin
        json result.add_grant(params)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_revoke_grant(resource, id, params)
      object = resource.camelize(true).constantize
      result = object.find(id)
      return status 404 if result.nil?
      begin
        json result.revoke_grant(params)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

  end

end
