# Doc placeholder
module ZimbraRestApi
  class DistributionList < ZimbraBase

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
