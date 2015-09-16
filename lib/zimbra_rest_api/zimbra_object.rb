module ZimbraRestApi

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

      def acl_factory(attrs = {})
        fail ArgumentError.new('Hash expected') unless attrs.is_a?Hash
        return if attrs.empty?
        attrs['grantee_class'] = Zimbra::ACL::TARGET_MAPPINGS[attrs['grantee_class']]
        Zimbra::ACL.new(grantee_name: attrs['grantee_name'],
                              grantee_class: attrs['grantee_class'],
                              name: attrs['name']
                              )
      end

      def add_grant(grant)
        acl = acl_factory(grant)
        if Zimbra::Directory::add_grant(self.zmobject, acl)
          self.class.find(self.id)
        else
          fail ZimbraRestApi::NotFound, "ZimbraRestApi::NotFound Grant #{acl.grantee_name}"
        end
      end

      def revoke_grant(grant)
        acl = acl_factory(grant)
        if Zimbra::Directory::revoke_grant(self.zmobject, acl)
          return self.class.find(self.id)
        else
          fail ZimbraRestApi::NotFound, "ZimbraRestApi::NotFound Grant #{acl.grantee_name}"
        end
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
        object.gsub!(/ZimbraRestApi::/,'')
        "Zimbra::#{object.camelize}".constantize
      end

      def search(object, query)
        zimbra_type = object.name.split(/::/).last.downcase
        search_hash = build_search_hash(query)
        search_hash.merge!(type: zimbra_type)
        query = search_hash.delete(:query)
        Zimbra::Directory.search(query, search_hash)
      end

      def build_search_hash(query = {})
        sort_options_hash = get_sort_ops(query)
        query_hash = {
          domain: query.delete('domain') || query.delete(:domain),
          query: hash_to_ldap(query)
        }
        query_hash.merge(sort_options_hash)
      end

      def get_sort_ops(query)
        page = query.delete('page') || 1
        limit = query.delete('per_page') || 25
        offset = page.to_i <= 1 ? 0 : ((page.to_i - 1) * limit.to_i)
        {limit: limit.to_i, offset: offset.to_i}
      end

      def hash_to_ldap(query = {})
        raw_filter = query.delete('raw_ldap_filter').to_s
        if query.delete('inverse_filter')
          result = query.map { |k, v| "(!(#{k}=#{v}))" }.join('')
        else
          result = query.map { |k, v| "(#{k}=#{v})" }.join('')
        end
        raw_filter << "(&#{result})"
        raw_filter
      end

      def zimbra_attrs_to_load=(array)
        klass_name = self.name.split(/::/)[1]
        klass = "Zimbra::#{klass_name}".constantize
        fail(ArgumentError, 'Must be an array') unless array.is_a?Array
        klass.zimbra_attrs_to_load = array
      end

      def zimbra_attrs_to_load
        klass_name = self.name.split(/::/)[1]
        klass = "Zimbra::#{klass_name}".constantize
        return [] if klass.zimbra_attrs_to_load.nil?
        klass.zimbra_attrs_to_load
      end
    end
  end

  class NotFound < StandardError; end

end
