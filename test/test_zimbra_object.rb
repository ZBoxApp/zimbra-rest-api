require 'test_helper'
require 'pp'

# Doc placeholder
class ZimbraObjectTest < Minitest::Test

  ZimbraObject = Struct.new(:name) do
    include ZimbraRestApi::ZimbraObject
  end

  def test_get_zimbra_object_should_return_a_zimbra_object
    zimbra_object = ZimbraObject.get_zimbra_object('Account')
    assert_equal(Zimbra::Account, zimbra_object)
    zimbra_object = ZimbraObject.get_zimbra_object('Domain')
    assert_equal(Zimbra::Domain, zimbra_object)
    assert_raises(Exception) do
      ZimbraObject.get_zimbra_object('NDN')
    end
  end

  def test_hash_to_ldap_should_return_a_ldap_query_string
    hash = { email: 'pbruna@itlinux.cl', uid: 'pbruna', cn: 'Patricio' }
    ldap_query = '(&(email=pbruna@itlinux.cl)(uid=pbruna)(cn=Patricio))'
    assert_equal(ldap_query, ZimbraObject.hash_to_ldap(hash))
  end

  def test_hash_to_ldap_should_return_a_ldap_query_string_with_only_one
    hash = { email: 'pbruna@itlinux.cl' }
    ldap_query = '(&(email=pbruna@itlinux.cl))'
    assert_equal(ldap_query, ZimbraObject.hash_to_ldap(hash))
  end

  # def test_all_with_query_should_call_directory_search
  #   query = { uid: 'pbruna', domain: 'itlinux.cl' }
  #   result = ZimbraObject.all(query, 'Account')
  #   assert result.is_a?(Array)
  # end

  def test_nil_result_if_all_finds_nothing
    query = { uid: 'pbruna', domain: 'exampe-nothig.cl' }
    result = ZimbraObject.all(query, 'Account')
    assert_nil result
  end

  def test_return_nil_if_object_not_found
    result = ZimbraObject.find('noexiste@itlinux.cl', 'Account')
    assert_nil result
  end

  def test_create_object_with_error_should_raise_with_error
    domain_name = ''
    params = {'name' => domain_name, 'zimbraSkinLogoURL' => 'http://itlinux.cl'}
    exception = assert_raises(Zimbra::HandsoapErrors::SOAPFault) { ZimbraRestApi::Domain.create(params) }
    assert exception.message
  end

  def test_count_should_return_a_hash_with_counters
    query = { domain: 'customer2.dev' }
    result = ZimbraObject.count(query, 'Account')
    assert_equal(Hash, result.class, 'should be a hash')
    assert(result[:count], 'should be a count field')
    assert(result[:count].is_a?(Fixnum), 'count should be a number')
  end

  def test_should_raise_to_many_search_results
    assert_raises(ZimbraRestApi::TO_MANY_RESULTS) do
      query = { 'mail' => '*.*', 'max_results' => 2 }
      ZimbraObject.all(query, 'ZimbraRestApi::Account')
    end
  end


end
