require 'test_helper'
require 'pp'

# Doc placeholder
class CosTest < Minitest::Test
  include Rack::Test::Methods

  def app
    ZimbraRestApi::App
  end


  def test_cos_all_should_return_all_cost
    get '/cos/'
    assert last_response.ok?
    result = JSON.parse(last_response.body)
    assert result.first['id']
    assert result.map(&:values).flatten.include?('unknow')
  end

  def test_get_cos_by_name
    get '/cos/unknow'
    assert last_response.ok?, 'Not ok response'
    result = JSON.parse(last_response.body)
    assert_equal('unknow', result['name'])
  end

end
