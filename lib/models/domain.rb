# Doc placeholder
module ZimbraRestApi
  class Domain < ZimbraBase

    def self.count_accounts(domain_id)
      Zimbra::Domain.count_accounts domain_id
    end

    def count_accounts
      zmobject.count_accounts
    end

    def set_max_accounts(total = 0, cos_quota = [])
      result = zmobject.set_max_accounts total, cos_quota
      Domain.new result
    end

  end
end
