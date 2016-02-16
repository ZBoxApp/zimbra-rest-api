require 'test_helper'
require 'pp'
require 'net/pop'

# Doc placeholder
class ArchivingTest < Minitest::Test

  include Rack::Test::Methods

  def app
    ZimbraRestApi::App
  end

  def setup
    @cos_id = '1b06e412-6951-4377-854d-9a7b3721ac5e'
    return unless ENV['zimbra_ne'] == 'TRUE'
    @test_account = Zimbra::Account.find_by_name('archive_test@itlinux.cl')
    @mailbox_archiving_name = "archive_test-#{Date.today.strftime('%Y%m%d')}@itlinux.cl.archive"
    prepare_test_account
  end

  def teardown
    return unless ENV['zimbra_ne'] == 'TRUE'
    prepare_test_account
  end

  def prepare_test_account
    @test_account.disable_archive
    @test_account.modify('zimbraArchiveAccount' => '')
    mailbox_archiving = Zimbra::Account.find_by_name(@mailbox_archiving_name)
    mailbox_archiving.delete if mailbox_archiving
  end

  def test_01_enable_mailbox_archive
    return unless ENV['zimbra_ne'] == 'TRUE'
    post "/accounts/#{@test_account.id}/archive/enable", cos_id: @cos_id
    assert @test_account.archive_enabled?, 'should be enabled'
    sleep 10
    assert_equal @mailbox_archiving_name, @test_account.archive_account
  end

  def test_02_disable_mailbox_archive
    return unless ENV['zimbra_ne'] == 'TRUE'
    @test_account.enable_archive(@cos_id)
    post "/accounts/#{@test_account.id}/archive/disable"
    assert !@test_account.archive_enabled?, 'Should be disabled'
  end

end
