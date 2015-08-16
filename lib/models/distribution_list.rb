# Doc placeholder
module ZimbraRestApi
  class DistributionList < ZimbraBase

    attr_reader :domain_id

    def initialize(zmobject)
      super
      @domain_id = name.split(/@/)[1]
    end

    def modify_members(members)
      zmobject.modify_members members
    end

    def update_attributes(attributes)
      if attributes['members']
        modify_members(attributes.delete('members'))
      end
      attributes.delete('members')
      super
    end

  end
end
