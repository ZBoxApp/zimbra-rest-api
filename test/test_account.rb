require 'test_helper'
require 'pp'
require 'net/pop'

# Doc placeholder
class AccountTest < Minitest::Test

  include Rack::Test::Methods

  def app
    ZimbraRestApi::App
  end

  def teardown
    @tmp_account = Zimbra::Account.find_by_name('tmp@zbox.cl')
    @tmp_account.delete if @tmp_account
  end

  def test_account_all
    get '/accounts/'
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert(result.size > 0, 'Should be an array with elements')
  end

  def test_get_account_with_id
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    get "/accounts/#{@account.id}"
    assert_equal(@account.name, JSON.parse(last_response.body)['name'])
  end

  def test_account_search
    get '/accounts/', zimbraIsAdminAccount: 'TRUE'
    result = JSON.parse(last_response.body)
    assert(result.first['name'].match(/admin/), 'Failed search')
  end

  def test_account_search_should_work_with_raw_ldap_filter
    ldap_filter = '(&(|(zimbraMailDeliveryAddress=*@zboxapp.dev)(zimbraMailDeliveryAddress=*@customer1.dev))(!(zimbraIsSystemAccount=TRUE)))'
    get '/accounts/', raw_ldap_filter: ldap_filter
    result = JSON.parse(last_response.body)
    names = result.map {|a| a['name']}
    assert(names.include?('admin@zboxapp.dev'), 'should include admin@zboxapp.dev')
    assert(names.include?('user1@customer1.dev'), 'should include user1@customer1.dev')
  end

  def test_sorting_options
    get '/accounts/', zimbraMailDeliveryAddress: 'cos_basic*@customer.dev', per_page: 100
    result = JSON.parse(last_response.body)
    assert result.size > 25, 'result should be > 25'
  end

  def test_raw_search_should_join_with_and_to_normal_query
    ldap_filter = '(&(|(zimbraMailDeliveryAddress=*@zboxapp.dev)(zimbraMailDeliveryAddress=*@customer.dev))(!(zimbraIsSystemAccount=TRUE)))'
    get '/accounts/', raw_ldap_filter: ldap_filter, zimbraIsAdminAccount: 'TRUE'
    result = JSON.parse(last_response.body)
    assert(result.first['name'].match(/admin/), 'Failed search')
  end

  def test_negative_search
    get '/accounts/', zimbraMailDeliveryAddress: 'z*@customer.dev', inverse_filter: true
    result = JSON.parse(last_response.body)
    names = result.map {|a| a['name']}
    assert(!names.include?('z2977@customer.dev'), 'should not include admin@zboxapp.dev')
  end

  def test_account_get_with_name
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    get "/accounts/#{@account.name}"
    assert_equal(@account.id, JSON.parse(last_response.body)['id'])
  end

  def test_create_account_and_return_new_object
    post '/accounts/', {name: 'tmp@zbox.cl', password: '12345678', displayName: 'tmp user'}
    result = JSON.parse(last_response.body)
    assert_equal 'tmp@zbox.cl', result['name'], 'name does not match'
    assert_equal 'tmp user', result['zimbra_attrs']['displayName'], 'displayName does not match'
  end

  def test_create_with_wrong_info_should_return_error
    post '/accounts/', {name: 'tmp@zbox.cl'}
    result = JSON.parse(last_response.body)
    assert result['errors'].any?
  end

  def test_return_404_if_account_doest_not_exists
    get '/accounts/xxx@xxx.com/'
    assert_equal 404, last_response.status
  end

  def test_return_empty_array_if_no_results
    get '/accounts', domain: 'xxx.com'
    result = JSON.parse(last_response.body)
    assert result.empty?
  end

  def test_update_no_existing_should_return_404
    time = Time.new.strftime('%Y%m%d%H%M%S')
    put '/accounts/xx@xxx.com/', {'sn' => time}
    assert_equal 404, last_response.status
  end

  def test_update_account_passing_attrs_and_return_updated_account
    time = Time.new.strftime('%Y%m%d%H%M%S')
    put '/accounts/pbruna@itlinux.cl', {'sn' => time}
    result = JSON.parse(last_response.body)
    assert_equal time, result['zimbra_attrs']['sn']
  end

  def test_update_account_name_should_work
    Zimbra::Account.create('tmp1@zbox.cl', '12345678')
    put '/accounts/tmp1@zbox.cl/', {'name' => 'tmp@zbox.cl'}
    result = JSON.parse(last_response.body)
    assert_equal 'tmp@zbox.cl', result['name']
  end

  def test_delete_account_should_return_200_ok
    name = Time.new.strftime('%Y%m%d%H%M%S') + '@zbox.cl'
    account = Zimbra::Account.create(name, '12345678')
    delete "/accounts/#{account.name}"
    assert_equal 200, last_response.status
  end

  def test_delete_account_should_return_404_if_not_account
    delete '/accounts/xxx@zbox.cl'
    assert_equal 404, last_response.status
  end

  def test_update_password_should_work
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    password = Time.new.strftime('%Y%m%d%H%M%S')
    put "/accounts/#{@account.name}/", {'password' => password}
    assert_equal 200, last_response.status
    pop = Net::POP3.new('localhost', 7110)
    assert pop.start('pbruna@itlinux.cl', password)
    pop.finish
  end

  def test_all_should_return_headers_info_for_pagination
    get '/accounts/', zimbraMailDeliveryAddress: 'cos_basic*@customer.dev'
    headers = last_response.headers
    assert(headers['X-Total'], 'should return total header')
    assert(headers['X-Total'].to_i > 0, 'total should be greater than 0')
    assert(headers['X-Page'], 'should return page header')
    assert(headers['X-Per-Page'], 'should return per page header')
  end

  def test_mailbox_path_should_return_size_and_store_id
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    get "/accounts/#{@account.id}/mailbox"
    assert last_response.ok?, 'wrong response'
    result = JSON.parse(last_response.body)
    assert result['size'], 'no size'
    assert result['store_id'], 'no store_id'
  end

  def test_mailbox_with_name_path_should_return_size_and_store_id
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    get "/accounts/#{@account.name}/mailbox"
    assert last_response.ok?, 'wrong response'
    result = JSON.parse(last_response.body)
    assert result['size'], 'no size'
    assert result['store_id'], 'no store_id'
  end


  def test_add_account_alias
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    alias_name = Time.new.strftime('%Y%m%d%H%M%S') + '@itlinux.cl'
    post "/accounts/#{@account.id}/add_alias", alias_name: alias_name
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert_equal(alias_name, result['alias_name'], 'No Alias')
  end

  def test_remove_add_account_alias
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    alias_name = Time.new.strftime('%Y%m%d%H%M%S') + '@itlinux.cl'
    post "/accounts/#{@account.id}/add_alias", alias_name: alias_name
    assert last_response.ok?
    post "/accounts/#{@account.id}/remove_alias", alias_name: alias_name
    result = JSON.parse(last_response.body)
    assert_equal(alias_name, result['alias_name'], 'No Alias')
  end

  def test_get_delegated_token
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
    get "/accounts/#{@account.id}/delegated_token"
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert(/[0-9]_.*/.match result['delegated_token'])
  end

  def test_get_count_accounts_should_work
    get '/accounts/count'
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert result['count'].is_a?(Fixnum)
  end

  def test_json_error_if_to_many_results
    get '/accounts/', max_results: 2
    assert last_response.ok?, 'response not ok'
    result = JSON.parse(last_response.body)
    assert result['errors']['ZimbraRestApi::TO_MANY_RESULTS']
  end

end
