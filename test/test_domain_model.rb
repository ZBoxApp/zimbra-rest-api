require 'test_helper'
require 'pp'

# Doc placeholder
class DomainModelTest < Minitest::Test

  def test_create_domain_should_return_the_object_with_info
    domain_name = Time.new.strftime('%Y%m%d%H%M%S') + '.com'
    params = {'name' => domain_name, 'zimbraSkinLogoURL' => 'http://itlinux.cl'}
    result = ZimbraRestApi::Domain.create(params)
    assert_equal domain_name, result.name
    assert_equal 'http://itlinux.cl', result.zimbra_attrs['zimbraSkinLogoURL']
  end

end
