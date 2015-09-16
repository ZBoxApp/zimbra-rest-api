require 'test_helper'
require 'pp'
require 'net/pop'

# Doc placeholder
class AccountTest < Minitest::Test

  include Rack::Test::Methods

  def app
    ZimbraRestApi::App
  end

  def setup
    @account = Zimbra::Account.find_by_name('pbruna@itlinux.cl')
  end

  def teardown
    @tmp_account = Zimbra::Account.find_by_name('tmp@zbox.cl')
    @tmp_account.delete if @tmp_account
  end

  def test_account_all
    get '/accounts/'
    assert last_response.ok?
    get '/accounts'
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert(result.size > 0, 'Should be an array with elements')
  end

  def test_get_account_with_id
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
    get "/accounts/", zimbraMailDeliveryAddress: '*@customer.dev', per_page: 1000
    result = JSON.parse(last_response.body)
    assert result.size > 25, 'result should be > 25'
  end

  def test_raw_search_should_join_with_and_to_normal_query
    ldap_filter = '(&(|(zimbraMailDeliveryAddress=*@zboxapp.dev)(zimbraMailDeliveryAddress=*@customer.dev))(!(zimbraIsSystemAccount=TRUE)))'
    get '/accounts/', raw_ldap_filter: ldap_filter, zimbraIsAdminAccount: 'TRUE'
    result = JSON.parse(last_response.body)
    assert(result.first['name'].match(/admin/), 'Failed search')
  end

  def test_account_get_with_name
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
    account = Zimbra::Account.create('tmp1@zbox.cl', '12345678')
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
    password = Time.new.strftime('%Y%m%d%H%M%S')
    put "/accounts/#{@account.name}/", {'password' => password}
    assert_equal 200, last_response.status
    pop = Net::POP3.new('localhost', 7110)
    assert pop.start('pbruna@itlinux.cl', password)
    pop.finish
  end

end
