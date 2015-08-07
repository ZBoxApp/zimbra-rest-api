require 'test_helper'
require 'pp'

# Doc placeholder
class AccountModelTest < Minitest::Test

  def setup
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
  end

  def test_find_should_search_by_id_if_id_passed
    result = ZimbraRestApi::Account.find(@account.id)
    assert_equal(@account.id, result.id)
  end

  def test_find_should_find_by_name_if_name_passed
    result = ZimbraRestApi::Account.find('pbruna@itlinux.cl')
    assert_equal(@account.id, result.id)
    assert_equal(ZimbraRestApi::Account, result.class)
  end


end
