require 'test_helper'
require 'pp'

# Doc placeholder
class DistributionListTest < Minitest::Test

  include Rack::Test::Methods

  def app
    ZimbraRestApi::App
  end

  def setup
    @dl = Zimbra::DistributionList.find_by_name('restringida@zbox.cl')
    @acl = Zimbra::ACL.new(grantee_name: 'pbruna@itlinux.cl', grantee_class: Zimbra::Account, name: 'sendToDistList')
  end

  def teardown
    @tmp_list = Zimbra::DistributionList.find_by_name('tmplist@zbox.cl')
    @tmp_list.delete if @tmp_list
  end

  def test_list_all
    get '/distribution_lists/'
    assert last_response.ok?
    get '/distribution_lists'
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert(result.size > 0, 'Should be an array with elements')
  end

  def test_get_distribution_lists_with_id
    get "/distribution_lists/#{@dl.id}"
    assert_equal(@dl.name, JSON.parse(last_response.body)['name'])
  end

  def test_get_distribution_lists_should_return_domain_id
    get "/distribution_lists/#{@dl.id}"
    result = JSON.parse(last_response.body)
    domain_name = @dl.name.split(/@/)[1]
    assert_equal(domain_name, result['domain_id'])
  end

  def test_distribution_lists_search
    get '/distribution_lists/', zimbraMailForwardingAddress: 'domain_admin@customer.dev'
    result = JSON.parse(last_response.body)
    assert(result.first['name'].match(/restringida/), 'Failed search')
  end

  def test_distribution_lists_get_with_name
    get "/distribution_lists/#{@dl.name}"
    assert_equal(@dl.id, JSON.parse(last_response.body)['id'])
  end

  def test_create_distribution_lists_and_return_new_object
    post '/distribution_lists/', {name: 'tmplist@zbox.cl', displayName: 'tmp list'}
    result = JSON.parse(last_response.body)
    assert_equal 'tmplist@zbox.cl', result['name'], 'name does not match'
    assert_equal 'tmp list', result['zimbra_attrs']['displayName'], 'displayName does not match'
  end

  def test_create_with_wrong_info_should_return_error
    post '/distribution_lists/', {name: ''}
    result = JSON.parse(last_response.body)
    assert result['errors'].any?
  end

  def test_return_404_if_account_doest_not_exists
    get '/distribution_lists/xxx@xxx.com/'
    assert_equal 404, last_response.status
  end

  def test_return_empty_array_if_no_results
    get '/distribution_lists', domain: 'xxx.com'
    result = JSON.parse(last_response.body)
    assert result.empty?
  end

  def test_update_no_existing_should_return_404
    time = Time.new.strftime('%Y%m%d%H%M%S')
    put '/distribution_lists/xx@xxx.com/', {'sn' => time}
    assert_equal 404, last_response.status
  end

  def test_update_dl_passing_attrs_and_return_updated_account
    time = Time.new.strftime('%Y%m%d%H%M%S')
    put "/distribution_lists/#{@dl.name}", {'displayName' => time}
    result = JSON.parse(last_response.body)
    assert_equal time, result['zimbra_attrs']['displayName']
  end

  def test_update_dl_name_should_work
    name = Time.new.strftime('%Y%m%d%H%M%S') + '@zbox.cl'
    dl = Zimbra::DistributionList.create(name)
    put "/distribution_lists/#{name}/", {'name' => 'tmplist@zbox.cl'}
    result = JSON.parse(last_response.body)
    assert_equal 'tmplist@zbox.cl', result['name']
  end

  def test_delete_dl_should_return_200_ok
    name = Time.new.strftime('%Y%m%d%H%M%S') + '@zbox.cl'
    dl = Zimbra::DistributionList.create(name)
    delete "/distribution_lists/#{dl.name}"
    assert_equal 200, last_response.status
  end

  def test_delete_dl_should_return_404_if_not_account
    delete '/distribution_lists/xxx@zbox.cl'
    assert_equal 404, last_response.status
  end

  def test_add_memebers_should_add_member
    dl = Zimbra::DistributionList.create('tmplist@zbox.cl')
    put "/distribution_lists/#{dl.name}", {'members' => ['pp@gmail.com', 'pa@gmail.com']}
    result = JSON.parse(last_response.body)
    assert result['members'].include?('pp@gmail.com')
  end

  def test_remove_memebers_should_remove_members
    dl = Zimbra::DistributionList.create('tmplist@zbox.cl')
    members = ['pbruna@gmail.com', 'pp@ppp.com']
    dl.modify_members(members)
    put "/distribution_lists/#{dl.name}", {'members' => ['3@gmail.com']}
    result = JSON.parse(last_response.body)
    assert result['members'].include?('3@gmail.com')
  end

  def test_add_grant_should_work
    Zimbra::Directory.revoke_grant(@dl, @acl)
    dl = Zimbra::DistributionList.find_by_name('restringida@zbox.cl')
    original_acls_size = dl.acls.size
    test_acl = {grantee_name: 'pbruna@itlinux.cl', grantee_class: 'usr', name: 'sendToDistList'}
    post "/distribution_lists/#{dl.name}/grants/add", test_acl
    result = JSON.parse(last_response.body)
    assert(result['acls'].size > original_acls_size)
  end

  def test_revoke_grant_should_work
    Zimbra::Directory.add_grant(@dl, @acl)
    dl = Zimbra::DistributionList.find_by_name('restringida@zbox.cl')
    original_acls_size = dl.acls.size
    test_acl = {grantee_name: 'pbruna@itlinux.cl', grantee_class: 'usr', name: 'sendToDistList'}
    post "/distribution_lists/#{dl.name}/grants/revoke", test_acl
    result = JSON.parse(last_response.body)
    assert(result['acls'].size < original_acls_size)
  end


end
