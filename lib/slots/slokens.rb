# frozen_string_literal: true

require 'jwt'
module Slots
  class Slokens
    attr_reader :token, :identifier, :exp, :iat, :extra_payload, :authenticated_record
    def initialize(decode: false, encode: false, token: nil, expected_keys: [], identifier: nil, extra_payload: nil)
      if decode
        @expected_keys = default_expected_keys + expected_keys
        decode(token)
      elsif encode
        @identifier = identifier
        @extra_payload = extra_payload.as_json
        encode()
        @valid = true
      else
        raise 'must encode or decode'
      end
    end
    def self.decode(token, *expected_keys)
      self.new(decode: true, token: token, expected_keys: expected_keys)
    end
    def self.encode(identifier, extra_payload)
      self.new(encode: true, identifier: identifier, extra_payload: extra_payload)
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

    def update_token
      encode
    end

    def session
      @extra_payload['session']
    end

    def payload
      @extra_payload.merge(
        'identifier' => @identifier,
        'exp' => @exp,
        'iat' => @iat,
      )
    end

    private
      def default_expected_keys
        ['identifier', 'exp', 'iat']
      end
      def secret
        Slots.configuration.secret(@iat)
      end
      def encode
        @exp = Slots.configuration.token_lifetime.from_now.to_i
        @iat = Time.now.to_i
        @token = JWT.encode self.payload, secret, 'HS256'
        @expired = false
        @valid = true
      end

      def decode(token)
        @token = token
        begin
          set_payload
          JWT.decode @token, secret, true, verify_iat: true, algorithm: 'HS256'
        rescue JWT::ExpiredSignature
          @expired = true
        rescue JWT::InvalidIatError, JWT::VerificationError, JWT::DecodeError, Slots::InvalidSecret, NoMethodError, JSON::ParserError
          @valid = false
        else
          @valid = payload.slice(*@expected_keys).compact.length == @expected_keys.length
        end
      end

      def set_payload
        encoded64 = @token.split('.')[1] || ''
        string_payload = Base64.decode64(encoded64)
        local_payload = JSON.parse(string_payload)
        raise JSON::ParserError unless local_payload.is_a?(Hash)
        @identifier = local_payload['identifier']
        @exp = local_payload['exp']&.to_i
        @iat = local_payload['iat']&.to_i
        @extra_payload = local_payload.except(*default_expected_keys)
      end
  end
end
