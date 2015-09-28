require 'test_helper'
require 'pp'

# Doc placeholder
class DomainTest < Minitest::Test

  include Rack::Test::Methods

  def app
    ZimbraRestApi::App
  end

  def setup
    @itlinux_domain = Zimbra::Domain.find_by_name('itlinux.cl')
  end

  def teardown
    @tmp_domain = ZimbraRestApi::Domain.find('tmp.com')
    @tmp_domain.delete if @tmp_domain
  end

  def test_domain_all
    get '/domains/'
    assert last_response.ok?
    get '/domains'
    assert last_response.ok?
  end

  def test_domain_get_with_zimbra_id
    get "/domains/#{@itlinux_domain.id}"
    assert_equal('itlinux.cl', JSON.parse(last_response.body)['name'])
  end

  def test_domain_get_with_search
    get '/domains/', zimbraDomainType: 'local', zimbraDomainName: '*.com'
    result = JSON.parse(last_response.body)
    assert(result.first['name'].match(/com$/), 'Failed search')
  end

  def test_domain_get_with_search_and_without_end_slash
    get '/domains', zimbraDomainType: 'local', zimbraDomainName: '*.com'
    result = JSON.parse(last_response.body)
    assert(result.first['name'].match(/com$/), 'Failed search')
  end

  def test_domain_get_with_name
    get '/domains/itlinux.cl/'
    assert_equal(@itlinux_domain.id, JSON.parse(last_response.body)['id'])
  end

  def test_domain_count_accounts_should_return_the_results
    get '/domains/itlinux.cl/count_accounts'
    result = JSON.parse(last_response.body)
    result.keys.each do |cosid|
      assert UUID.validate cosid
    end
  end

  def test_domain_distribution_list_nested_path
    get '/domains/customer.dev/distribution_lists'
    result = JSON.parse(last_response.body)
    assert result.first['zmobject'].match(/Zimbra::DistributionList/), 'Should be a domain'
    assert result.first['name'].match(/customer/), 'Should have the same domain'
    assert(result.size > 1)
  end

  def test_domain_accounts_nested_path
    get '/domains/zbox.cl/accounts'
    result = JSON.parse(last_response.body)
    assert result.first['zmobject'].match(/Zimbra::Account/), 'Should be an account'
  end

  def test_create_domain_and_return_new_object
    post '/domains/', {name: 'tmp.com', zimbraSkinLogoURL: 'http://123456.com'}
    result = JSON.parse(last_response.body)
    assert_equal 'tmp.com', result['name'], 'name does not match'
    assert_equal 'http://123456.com', result['zimbra_attrs']['zimbraSkinLogoURL'], 'zimbraSkinLogoURL does not match'
  end

  def test_create_with_wrong_info_should_return_error
    post '/domains/', {name: ' '}
    result = JSON.parse(last_response.body)
    assert result['errors'].any?
  end

  def test_return_404_if_domain_doest_not_exists
    get '/domains/xxx.com/'
    assert_equal 404, last_response.status
  end

  def test_return_empty_array_if_no_results
    get '/domains', zimbraDomainType: 'test'
    result = JSON.parse(last_response.body)
    assert result.empty?
  end

  def test_update_no_existing_domain_should_return_404
    time = Time.new.strftime('%Y%m%d%H%M%S')
    put '/domains/zboddx.cl/', {'o' => time}
    assert_equal 404, last_response.status
  end

  def test_update_domain_passing_attrs_and_return_domain
    time = Time.new.strftime('%Y%m%d%H%M%S')
    put '/domains/zbox.cl', {'o' => time}
    result = JSON.parse(last_response.body)
    assert_equal time, result['zimbra_attrs']['o']
  end

  def test_update_domain_name_should_record_error
    put '/domains/zbox.cl/', {'name' => 'zboxnoname.cl'}
    result = JSON.parse(last_response.body)
    assert result['errors'].any?
  end

  def test_delete_domain_should_return_200_ok
    domain_name = Time.new.strftime('%Y%m%d%H%M%S') + '.com'
    params = {'name' => domain_name, 'zimbraSkinLogoURL' => 'http://itlinux.cl'}
    domain = ZimbraRestApi::Domain.create(params)
    delete "/domains/#{domain.name}"
    assert_equal 200, last_response.status
  end

  def test_delete_domain_should_return_error_if_it_fails
    delete '/domains/zbox.cl'
    result = JSON.parse(last_response.body)
    assert result['errors'].any?
  end

  def test_search_should_work_with_nested_dl_path
    get '/domains/customer.dev/distribution_lists', mail: '*restringida*'
    result = JSON.parse(last_response.body)
    assert_equal(1, result.size)
    get '/domains/customer.dev/distribution_lists', mail: 'restringida@customer.dev'
    result = JSON.parse(last_response.body)
    assert_equal(1, result.size)
  end

  def test_all_should_return_headers_info_for_pagination
    get '/domains/'
    headers = last_response.headers
    assert(headers['X-Total'], 'should return total header')
    assert(headers['X-Page'], 'should return page header')
    assert(headers['X-Per-Page'], 'should return per page header')
  end

  def test_should_return_pagination_0_if_search_fail_or_invalid
    get '/domains/', name: 'kdmalkmdla.com'
    headers = last_response.headers
    assert(headers['X-Total'], 'should return total header')
    assert_equal(0, headers['X-Total'], 'should be 0')
    assert(headers['X-Page'], 'should return page header')
    assert(headers['X-Per-Page'], 'should return per page header')
  end

end
