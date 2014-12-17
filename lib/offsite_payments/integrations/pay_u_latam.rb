require 'builder'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PayULatam

      mattr_accessor :test_url
      self.test_url = 'https://stg.api.payulatam.com/payments-api/4.0/service.cgi'

      mattr_accessor :production_url
      self.production_url = 'https://api.payulatam.com/payments-api/4.0/service.cgi'

      QUERIES_API_TEST_URL = 'https://stg.api.payulatam.com/reports-api/4.0/service.cgi'
      QUERIES_API_LIVE_URL = 'https://api.payulatam.com/reports-api/4.0/service.cgi'

      QUERY_COMMANDS = {
          :orderId       => 'ORDER_DETAIL',
          :referenceCode => 'ORDER_DETAIL_BY_REFERENCE_CODE',
          :transactionId => 'TRANSACTION_RESPONSE_DETAIL',
      }

      def self.service_url
        mode = OffsitePayments.mode
        case mode
          when :production
            self.production_url
          when :test
            self.test_url
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.queries_url
        mode = OffsitePayments.mode
        case mode
          when :production
            QUERIES_API_LIVE_URL
          when :test
            QUERIES_API_TEST_URL
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.helper(order, account, options = {})
        Helper.new(order, account, options)
      end

      class Helper < OffsitePayments::Helper

        mapping :customer,
                :name       => 'name',
                :email      => 'email',
                :phone      => 'phone',
                :dni_number => 'dniNumber'

        mapping :billing_address,
                :address1 => 'address1',
                :city     => 'city',
                :state    => 'state',
                :country  => 'country'

        mapping :amount, 'amount'
        mapping :currency, 'currency'
        mapping :order, 'order'
        mapping :description, 'description'

        mapping :language, 'language'
        mapping :payment_method, 'paymentMethod'
        mapping :expiration_date, 'expirationDate'

        # These credentials are mandatory:
        #
        # credential2: api_login
        # credential3: api_key
        # credential4: account_id
        def initialize(order, merchant_id, options = {})
          super
          @merchant_id = merchant_id
          @options     = options

          add_field 'language', 'en'
        end

        def api_login
          @options[:credential2]
        end

        def api_key
          @options[:credential3]
        end

        def account_id
          @options[:credential4]
        end

        def merchant_id
          @merchant_id
        end

        def form_method
          'GET'
        end

        def form_fields
          cash_request = send_request(PayULatam.service_url, build_cash_request)

          raise ActionViewHelperError, "Invalid response: #{cash_request}" unless success_cash_request_response?(cash_request)

          {
              :order_id        => cash_request['transactionResponse']['orderId'],
              :transaction_id  => cash_request['transactionResponse']['transactionId'],
              :url             => cash_request['transactionResponse']['extraParameters']['URL_PAYMENT_RECEIPT_HTML'],
              :expiration_date => cash_request['transactionResponse']['extraParameters']['EXPIRATION_DATE'],
          }
        end

        def order_status(order_id)
          request_status = send_request(PayULatam.queries_url, build_query_request(:orderId, order_id))

          raise ActionViewHelperError, "Invalid response: #{request_status}" unless success_response?(request_status)
          # Not found?
          return nil if request_status['result'].nil? or request_status['result']['payload'].nil?

          {
              :order_id       => request_status['result']['payload']['id'],
              :status         => request_status['result']['payload']['status'],
              :reference_code => request_status['result']['payload']['referenceCode'],
              :description    => request_status['result']['payload']['description']
          }
        end

        def transaction_status(transaction_id)
          request_status = send_request(PayULatam.queries_url, build_query_request(:transactionId, transaction_id))

          raise ActionViewHelperError, "Invalid response: #{request_status}" unless success_response?(request_status)
          # Not found?
          return nil if request_status['result'].nil? or request_status['result']['payload'].nil?

          {
              :status            => request_status['result']['payload']['state'],
              :traceability_code => request_status['result']['payload']['trazabilityCode'],
              :authorization     => request_status['result']['payload']['authorizationCode']
          }
        end

        def orders_statuses(reference_code)
          request_status = send_request(PayULatam.queries_url, build_query_request(:referenceCode, reference_code))

          raise ActionViewHelperError, "Invalid response: #{request_status}" unless success_response?(request_status)
          # Not found?
          return nil if request_status['result'].nil?

          request_status['result']['payload']
        end

        private

        def send_request(url, request_body)
          uri              = URI.parse(url)
          http             = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl     = true
          # PayULatam's test server has an improperly installed cert
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if test?

          request              = Net::HTTP::Post.new(uri.request_uri)
          request['Accept']    = 'application/json'
          request.content_type = 'application/json'
          request.body         = request_body

          response = http.request(request)
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end

        def build_cash_request
          shipping_address           = {}
          shipping_address[:street1] = @fields['address1'] unless @fields['address1'].nil?
          shipping_address[:city]    = @fields['city'] unless @fields['city'].nil?
          shipping_address[:state]   = @fields['state'] unless @fields['state'].nil?
          shipping_address[:country] = @fields['country'] unless @fields['country'].nil?
          shipping_address[:phone]   = @fields['phone'] unless @fields['phone'].nil?

          buyer                   = {}
          buyer[:fullName]        = @fields['name'] unless @fields['name'].nil?
          buyer[:emailAddress]    = @fields['email'] unless @fields['email'].nil?
          buyer[:dniNumber]       = @fields['dniNumber'] unless @fields['dniNumber'].nil?
          buyer[:shippingAddress] = shipping_address

          order                    = {}
          order[:accountId]        = account_id
          order[:referenceCode]    = @fields['order']
          order[:description]      = @fields['description']
          order[:language]         = @fields['language']
          order[:signature]        = signature
          order[:shippingAddress]  = {:country => @fields['country']} unless @fields['country'].nil?
          order[:buyer]            = buyer
          order[:additionalValues] = {:TX_VALUE => {:value => @fields['amount'].to_i, :currency => @fields['currency']}}

          transaction                  = {}
          transaction[:order]          = order
          transaction[:type]           = 'AUTHORIZATION_AND_CAPTURE'
          transaction[:paymentMethod]  = @fields['paymentMethod']
          transaction[:expirationDate] = @fields['expirationDate'] unless @fields['expirationDate'].nil?

          request               = build_base_request('SUBMIT_TRANSACTION')
          request[:transaction] = transaction

          request.to_json
        end

        def build_query_request(key, value)
          request           = build_base_request(QUERY_COMMANDS[key])
          request[:details] = {key => value}

          request.to_json
        end

        def build_base_request(command)
          request            = {}
          request[:language] = @fields['language']
          request[:command]  = command
          # Should always be false, even in test mode
          request[:test]     = 'false'
          request[:merchant] = {:apiLogin => api_login, :apiKey => api_key}
          request
        end

        def signature
          raw = "#{api_key}~#{merchant_id}~#{@fields['order']}~#{@fields['amount']}~#{@fields['currency']}"
          Digest::MD5.hexdigest(raw)
        end

        def success_cash_request_response?(cash_request_response)
          success_response?(cash_request_response) and cash_request_response['transactionResponse'].is_a?(Hash) and cash_request_response['transactionResponse']['errorCode'].nil?
        end

        def success_response?(response)
          response.is_a?(Hash) and response['code'] == 'SUCCESS' and response['error'].nil?
        end
      end
    end
  end
end
