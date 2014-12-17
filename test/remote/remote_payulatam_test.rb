# encoding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class RemotePayULatamTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    # The tests will work with Colombia only, the payload will be different in other countries
    # See http://docs.payulatam.com/en/api-integration/proof-of-payment/
    options = {
        :amount      => 6000,
        :currency    => 'COP',
        :credential2 => '11959c415b33d0c',
        :credential3 => '6u39nqhq8ftd0hlvnjfs66eh8c',
        :credential4 => '500538'
    }
    @helper = PayULatam::Helper.new('testColombia3', '500238', options)
  end

  def test_setup_cash_request
    @helper.add_field :description, 'Test order Colombia Baloto'
    @helper.add_field PayULatam::Helper.mappings[:payment_method], 'BALOTO'
    @helper.add_field PayULatam::Helper.mappings[:expiration_date], '2015-01-25T16:49:18'

    @helper.add_fields :customer,
                       :name       => 'José Pérez',
                       :email      => 'test@payulatam.com',
                       :phone      => '5582254',
                       :dni_number => '1155255887'

    @helper.billing_address :address1 => 'Calle 93 B 17 – 25',
                            :city     => 'Bogotá',
                            :state    => 'Cundinamarca',
                            :country  => 'CO'

    cash_request = @helper.form_fields

    order_status = @helper.order_status(cash_request[:order_id])
    assert_equal 'IN_PROGRESS', order_status[:status]

    tx_status = @helper.transaction_status(cash_request[:transaction_id])
    assert_equal 'PENDING', tx_status[:status]

    status = @helper.orders_statuses(order_status[:reference_code])
    assert_equal 'IN_PROGRESS', status[-1]['status']
  end
end
