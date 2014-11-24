require File.expand_path('../../test_helper', __FILE__)

class RemotePayULatamTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    fixtures = fixtures(:pay_u_latam)
    options  = {:amount => 500, :currency => 'USD', :credential2 => fixtures[:credential2], :credential3 => fixtures[:credential3], :credential4 => fixtures[:credential4]}
    @helper  = PayULatam::Helper.new('order-500', 'cody@example.com', options)
  end

  def test_setup_pse
    body = @helper.initiate_pse_transaction(500, { :ip => '127.0.0.1'})
    puts body.inspect
  end
end
