require 'builder'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module PayULatam

      mattr_accessor :test_url
      self.test_url = 'https://gateway2.pagosonline.net/ws/WebServicesClientesUT'

      mattr_accessor :production_url
      self.production_url = 'https://gateway2.pagosonline.net/ws/WebServicesClientesUT'

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

      def self.notification(post)
        Notification.new(post)
      end

      class Helper < OffsitePayments::Helper
        # Replace with the real mapping
        mapping :account, ''
        mapping :amount, ''

        mapping :order, ''

        mapping :customer, :first_name => '',
                :last_name             => '',
                :email                 => '',
                :phone                 => ''

        mapping :billing_address, :city => '',
                :address1               => '',
                :address2               => '',
                :state                  => '',
                :zip                    => '',
                :country                => ''

        mapping :notify_url, ''
        mapping :return_url, ''
        mapping :cancel_return_url, ''
        mapping :description, ''
        mapping :tax, ''
        mapping :shipping, ''

        # All credentials are mandatory and need to be set
        #
        # credential2: usuario_id
        # credential3: cuenta_id
        # credential4: token password
        def initialize(order, account, options = {})
          super
          @options = options
       end

        ENVELOPE_NAMESPACES = {
            'xmlns:xsd'  => 'http://www.w3.org/2001/XMLSchema',
            'xmlns:xsi'  => 'http://www.w3.org/2001/XMLSchema-instance',
            'xmlns:impl' => 'https://gateway2.pagosonline.net/ws/WebServicesClientesUT',
            'xmlns:env'  => 'http://schemas.xmlsoap.org/soap/envelope/',
            'xmlns:ins0' => 'http://axis.web.v2.pagosonline.net',
            'xmlns:ins1' => 'urn:Pagosonline',
            'xmlns:ins2' => 'http://common.v2.pagosonline.net',
            'xmlns:ins3' => 'http://xml.apache.org/xml-soap',
            'xmlns:ins4' => 'http://client.v2.pagosonline.net',
            'xmlns:ins5' => 'http://controllers.web.v2.pagosonline.net'
        }

        def usuario_id
          @options[:credential2]
        end

        def cuenta_id
          @options[:credential3]
        end

        def token_id
          usuario_id
        end

        def token_password
          @options[:credential4]
        end

        def initiate_pse_transaction(money, options)
          body = build_request(build_initiate_pse_transaction_request(money, options))
          do_request(PayULatam.service_url, body)
        end

        private

        def build_initiate_pse_transaction_request(money, options = {})
          xml = Builder::XmlMarkup.new

          xml.tag! 'impl:iniciarTransaccionPseConInformacionAdicional' do
            xml.tag! 'usuarioId', usuario_id
            xml.tag! 'cuentaId', cuenta_id
            xml.tag! 'referencia', options[:order_id]
            xml.tag! 'descripcion', options[:description]
            xml.tag! 'valor', (money / 100).to_i
            xml.tag! 'iva', options[:tax]
            xml.tag! 'emailComprador', options[:email]
            xml.tag! 'direccionIpComprador', options[:ip]
            xml.tag! 'nombreComprador', options[:name]
            xml.tag! 'telefonoComprador', options[:phone]
            xml.tag! 'cookie', options[:cookie]
            xml.tag! 'agenteNavegador', options[:user_agent]
            xml.tag! 'urlRespuesta', options[:success_url]
            xml.tag! 'urlConfirmacion', options[:confirmation_url]
            xml.tag! 'codigoBancoPse', options[:bank_code]
            xml.tag! 'tipoCliente', 'N'
            xml.tag! 'pseReferencia1', options[:ip]
            xml.tag! 'pseReferencia2', 'CC'
            xml.tag! 'pseReferencia3', options[:document_id]
            # TODO
            xml.tag! 'extra1', signature(nil, options)
          end

          xml.target!
        end

        def signature(salt, options)
          raw = "#{options[:email]}~^~#{options[:ip]}CC#{options[:document_id]}#{salt}"
          Digest::SHA256.hexdigest(raw)[0..32]
        end

        def build_request(body)
          xml = Builder::XmlMarkup.new

          xml.instruct!
          xml.tag! 'env:Envelope', ENVELOPE_NAMESPACES do
            xml.tag! 'env:Header' do
              xml.tag! 'wsse:Security', {'env:mustUnderstand' => '1', 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'} do
                xml.tag! 'wsse:UsernameToken' do
                  xml.tag! 'wsse:Username', token_id
                  xml.tag! 'wsse:Password', token_password, 'Type' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText'
                end
              end
            end
            xml.tag! 'env:Body', {'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema'} do
              xml << body
            end
          end
          xml.target!
        end

        def do_request(url, post_body = nil)
          uri = URI.parse(url)

          http         = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          headers      = {'SOAPAction'   => url,
                          'Content-Type' => 'text/xml; charset=utf-8'}
          request      = Net::HTTP::Post.new(uri.request_uri, headers)
          request.body = post_body

          http.request(request).body
        end
      end

      class Notification < OffsitePayments::Notification
        def complete?
          params['']
        end

        def item_id
          params['']
        end

        def transaction_id
          params['']
        end

        # When was this payment received by the client.
        def received_at
          params['']
        end

        def payer_email
          params['']
        end

        def receiver_email
          params['']
        end

        def security_key
          params['']
        end

        # the money amount we received in X.2 decimal.
        def gross
          params['']
        end

        # Was this a test transaction?
        def test?
          params[''] == 'test'
        end

        def status
          params['']
        end

        # Acknowledge the transaction to PayULatam. This method has to be called after a new
        # apc arrives. PayULatam will verify that all the information we received are correct and will return a
        # ok or a fail.
        #
        # Example:
        #
        #   def ipn
        #     notify = PayULatamNotification.new(request.raw_post)
        #
        #     if notify.acknowledge
        #       ... process order ... if notify.complete?
        #     else
        #       ... log possible hacking attempt ...
        #     end
        def acknowledge(authcode = nil)
          payload = raw

          uri = URI.parse(PayULatam.notification_confirmation_url)

          request = Net::HTTP::Post.new(uri.path)

          request['Content-Length'] = "#{payload.size}"
          request['User-Agent']     = 'Active Merchant -- http://activemerchant.org/'
          request['Content-Type']   = 'application/x-www-form-urlencoded'

          http             = Net::HTTP.new(uri.host, uri.port)
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
          http.use_ssl     = true

          response = http.request(request, payload)

          # Replace with the appropriate codes
          raise StandardError.new("Faulty PayULatam result: #{response.body}") unless ['AUTHORISED', 'DECLINED'].include?(response.body)
          response.body == 'AUTHORISED'
        end

        private

        # Take the posted data and move the relevant data into a hash
        def parse(post)
          @raw = post.to_s
          for line in @raw.split('&')
            key, value  = *line.scan(%r{^([A-Za-z0-9_.-]+)\=(.*)$}).flatten
            params[key] = CGI.unescape(value.to_s) if key.present?
          end
        end
      end
    end
  end
end
