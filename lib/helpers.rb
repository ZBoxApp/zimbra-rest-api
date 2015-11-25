module ZimbraRestApi
  module Helpers

    def resource_index(resource, params = {})
      object = object_factory(resource)
      begin
        result = object.all(params)
        return json({}) if result.nil?
        set_pagination_headers(result[:search_total], params)
        json(result[:results])
      rescue ZimbraRestApi::TO_MANY_RESULTS => e
        result = { 'errors' => { e.to_s => e.message } }
        json result
      end
    end

    def resource_count(resource, params = {})
      object = object_factory(resource)
      json object.count(params)
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
      headers('X-Total' => total.to_s,
              'X-Page' => (pagination['page'] || 1).to_s,
              'X-Per-Page' => (pagination['per_page'] || 25).to_s
              )
    end

    def object_factory(resource)
      "ZimbraRestApi::#{resource.camelize(true)}".constantize
    end

  end

end
