# frozen_string_literal: true

require 'jwt'
module Slots
  class Slokens
    attr_reader :token, :exp, :iat, :extra_payload, :authentication_model_values, :session
    def initialize(decode: false, encode: false, token: nil, authentication_record: nil, extra_payload: nil, session: nil)
      if decode
        @token = token
        decode()
      elsif encode
        @authentication_model_values = authentication_record.as_json
        @extra_payload = extra_payload.as_json
        @session = session
        update_iat
        update_exp
        encode()
        @valid = true
      else
        raise 'must encode or decode'
      end
    end
    def self.decode(token)
      self.new(decode: true, token: token)
    end
    def self.encode(authentication_record, session = '', extra_payload)
      self.new(encode: true, authentication_record: authentication_record, session: session, extra_payload: extra_payload)
    end

    def expired?
      @expired
    end

    def valid?
      @valid
    end

    def valid!
      raise InvalidToken, "Invalid Token" unless valid?
      self
    end

    def update_token_data(authentication_record, extra_payload)
      @authentication_model_values = authentication_record.as_json
      @extra_payload = extra_payload.as_json
      update_iat
      encode
    end

    def update_token(authentication_record, extra_payload)
      update_exp
      update_token_data(authentication_record, extra_payload)
    end

    def payload
      {
        authentication_model_key => @authentication_model_values,
        'exp' => @exp,
        'iat' => @iat,
        'session' => @session,
        'extra_payload' => @extra_payload,
      }
    end

    private
      def authentication_model_key
        Slots.configuration.authentication_model.name.underscore
      end

      def default_expected_keys
        ['exp', 'iat', 'session', authentication_model_key]
      end
      def secret
        Slots.configuration.secret(@iat)
      end
      def update_iat
        @iat = Time.now.to_i
      end
      def update_exp
        @exp = Slots.configuration.token_lifetime.from_now.to_i
      end
      def encode
        @token = JWT.encode self.payload, secret, 'HS256'
        @expired = false
        @valid = true
      end

      def decode
        begin
          set_payload
          JWT.decode @token, secret, true, verify_iat: true, algorithm: 'HS256'
        rescue JWT::ExpiredSignature
          @expired = true
        rescue JWT::InvalidIatError, JWT::VerificationError, JWT::DecodeError, Slots::InvalidSecret, NoMethodError, JSON::ParserError
          @valid = false
        else
          @valid = payload.slice(*default_expected_keys).compact.length == default_expected_keys.length
        end
      end

      def set_payload
        encoded64 = @token.split('.')[1] || ''
        string_payload = Base64.decode64(encoded64)
        local_payload = JSON.parse(string_payload)
        raise JSON::ParserError unless local_payload.is_a?(Hash)
        @exp = local_payload['exp']&.to_i
        @iat = local_payload['iat']&.to_i
        @session = local_payload['session']
        @authentication_model_values = local_payload[authentication_model_key]
        @extra_payload = local_payload['extra_payload']
      end
  end
end
