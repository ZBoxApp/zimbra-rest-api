# Doc placeholder
module ZimbraRestApi
  class Domain < ZimbraBase

    def self.count_accounts(domain_id)
      Zimbra::Domain.count_accounts domain_id
    end

    def count_accounts
      zmobject.count_accounts
    end

  end
end
