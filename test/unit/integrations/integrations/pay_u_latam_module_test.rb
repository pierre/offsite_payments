require 'test_helper'

class PayULatamTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of PayULatam::Notification, PayULatam.notification('name=cody')
  end
end
