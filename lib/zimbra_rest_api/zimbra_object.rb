module ZimbraRestAPI

  # Class placeholder
  module ZimbraObject
    def self.included(base)
      base.send :include, InstanceMethods
      base.extend ClassMethods
    end

    module InstanceMethods
      def to_json(arg = nil)
        hash = {}
        self.instance_variables.each do |var|
          name = var.to_s.gsub(/@/, '')
          hash[name] = self.instance_variable_get var
        end
        hash.to_json
      end

      def from_json! string
        JSON.load(string).each do |var, val|
            self.instance_variable_set var, val
        end
      end

      def update_attributes(attributes)
        fail ArgumentError.new('Hash expected') unless attributes.is_a?Hash
        result = zmobject.modify(attributes)
        self.class.find(self.id)
      end

      def delete
        zmobject.delete
      end

      def add_grant(attrs)
        fail ArgumentError.new('Hash expected') unless attrs.is_a?Hash
        attrs['grantee_class'] = Zimbra::ACL::TARGET_MAPPINGS[attrs['grantee_class']]
        acl = Zimbra::ACL.new(grantee_name: attrs['grantee_name'],
                              grantee_class: attrs['grantee_class'],
                              name: attrs['name']
                              )
        Zimbra::Directory::add_grant(self.zmobject, acl)
        self.class.find(self.id)
      end

      def revoke_grant(attrs)
        fail ArgumentError.new('Hash expected') unless attrs.is_a?Hash
        attrs['grantee_class'] = Zimbra::ACL::TARGET_MAPPINGS[attrs['grantee_class']]
        acl = Zimbra::ACL.new(grantee_name: attrs['grantee_name'],
                              grantee_class: attrs['grantee_class'],
                              name: attrs['name']
                              )
        Zimbra::Directory::revoke_grant(self.zmobject, acl)
        self.class.find(self.id)
      end

    end

    # Doc placeholder
    module ClassMethods

      def all(query = {}, object = nil)
        query ||= {}
        zimbra_object = get_zimbra_object(object)
        results = search(zimbra_object, query)
        results.nil? ? nil : results.map do |o|
          new(o)
        end
      end

      def find(query, object = nil)
        zimbra_object = get_zimbra_object(object)
        if UUID.validate(query)
          result = zimbra_object.find_by_id(query)
        else
          result = zimbra_object.find_by_name(query)
        end
        result.nil? ? nil : new(result)
      end

      def create(params = {}, object = nil)
        zimbra_object = get_zimbra_object(object)
        name = params.delete('name')
        result = zimbra_object.create(name, params)
        new(result)
      end

      def get_zimbra_object(object)
        object ||= self.is_a?(Class) ? name : self.class.name
        "Zimbra::#{object.camelize}".constantize
      end

      def search(object, query)
        zimbra_type = object.name.split(/::/).last.downcase
        search_hash = build_search_hash(query)
        Zimbra::Directory.search(search_hash[:query],
                                 type: zimbra_type,
                                 domain: search_hash[:domain],
                                 **search_hash[:sorting])
      end

      def build_search_hash(query = {})
        {
          domain: query.delete(:domain),
          sorting: get_sort_ops(query),
          query: hash_to_ldap(query)
        }

      end

      def get_sort_ops(query)
        page = query.delete(:page) || 1
        limit = query.delete(:per_page) || 25
        offset = page.to_i <= 1 ? 0 : ((page.to_i - 1) * limit.to_i)
        { limit: limit.to_i, offset: offset.to_i }
      end

      def hash_to_ldap(query = {})
        return '' if query.keys.size < 0
        result = query.map { |k, v| "(#{k}=#{v})" }.join('')
        return "(&#{result})" if query.keys.size > 1
        result
      end
    end
  end
end
