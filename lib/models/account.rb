# Doc placeholder
module ZimbraRestApi
  class Account < ZimbraBase

    def add_alias(alias_name)
      zmobject.add_alias(alias_name)
    end

    def delegated_auth_token
      zmobject.delegated_auth_token
    end

    def mailbox
      zmobject.mailbox
    end

    def remove_alias(alias_name)
      zmobject.remove_alias(alias_name)
    end

    def self.create(params = {})
      name = params.delete('name')
      password = params.delete('password')
      result = Zimbra::Account.create(name, password, params)
      new(result)
    end

    def self.mailbox(account_id)
      Zimbra::Account.mailbox account_id
    end

    def set_password(new_password)
      zmobject.set_password new_password
    end

    def update_attributes(attributes)
      if attributes['password']
        set_password(attributes.delete('password'))
      end
      attributes.delete('password')
      super
    end

  end
end
