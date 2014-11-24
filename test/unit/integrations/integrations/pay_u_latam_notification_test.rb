require 'test_helper'

class PayULatamNotificationTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    @pay_u_latam = PayULatam::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @pay_u_latam.complete?
    assert_equal "", @pay_u_latam.status
    assert_equal "", @pay_u_latam.transaction_id
    assert_equal "", @pay_u_latam.item_id
    assert_equal "", @pay_u_latam.gross
    assert_equal "", @pay_u_latam.currency
    assert_equal "", @pay_u_latam.received_at
    assert @pay_u_latam.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @pay_u_latam.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @pay_u_latam.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end
end
