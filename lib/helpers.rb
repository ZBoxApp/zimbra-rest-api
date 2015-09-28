module ZimbraRestApi
  module Helpers

    def resource_index(resource, params = {})
      object = object_factory(resource)
      result = object.all(params)
      total = object.count(params)
      set_pagination_headers(total[:count], params)
      result.nil? ? json({}) : json(result)
    end

    def resource_show(resource, id)
      object = object_factory(resource)
      result = object.find(id)
      return json(result) if result
      status 404
    end

    def resource_create(resource, params)
      object = object_factory(resource)
      begin
        json object.create(params)
      rescue Zimbra::HandsoapErrors::SOAPFault => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_update(resource, id, params)
      object = object_factory(resource)
      result = object.find(id)
      return status 404 if result.nil?
      begin
        json result.update_attributes(params)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_delete(resource, id)
      object = object_factory(resource)
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
      object = object_factory(resource)
      result = object.find(id)
      return status 404 if result.nil?
      begin
        json result.add_grant(params)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    def resource_revoke_grant(resource, id, params)
      object = object_factory(resource)
      result = object.find(id)
      return status 404 if result.nil?
      begin
        json result.revoke_grant(params)
      rescue Exception => e
        json({ errors: [ e.message ]})
      end
    end

    def set_pagination_headers(total, pagination)
      headers('X-Total' => total,
              'X-Page' => (pagination['page'] || 1),
              'X-Per-Page' => (pagination['per_page'] || 25)
              )
    end

    def object_factory(resource)
      "ZimbraRestApi::#{resource.camelize(true)}".constantize
    end

  end

end
