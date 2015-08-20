module ZimbraRestApi
  class ZimbraBase
    include ZimbraRestApi::ZimbraObject

    attr_accessor :zmobject

    def initialize(zmobject)
      @zmobject = zmobject
      @zmobject.acls # Force loading
      instance_variables = get_instance_values(zmobject)
      set_instance_variables(instance_variables)
    end

    private

    def get_instance_values(object)
      return nil if object.nil?
      hash = {}
      object.instance_variables.each do |v|
        hash[v] = object.instance_variable_get(v)
      end
      hash
    end

    def set_instance_variables(instance_variables)
      instance_variables.each do |name, value|
        instance_variable_set(name, value)
        self.class.send(:attr_accessor, name.to_s.gsub(/@/, ''))
      end
    end

  end
end
