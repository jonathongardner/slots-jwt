# frozen_string_literal: true

require 'jwt'
module Slots
  class AuthenticationFailed < StandardError
  end
  class InvalidPayload < StandardError
  end
  class InvalidSecret < StandardError
  end
  class InvalidToken < StandardError
  end
  class Slokens
    attr_reader :token, :identifier, :exp, :iat, :extra_payload
    def initialize(token: nil, identifier: nil, extra_payload: extra_payload)
      if token
        decode(token)
        @valid = true
      else
        @extra_payload = extra_payload.as_json
        encode(identifier)
        @valid = true
      end
    end
    def self.decode(token)
      self.new(token: token)
    end
    def self.encode(identifier, extra_payload)
      self.new(identifier: identifier, extra_payload: extra_payload)
    end

    def valid?
      @valid
    end

    def payload
      @extra_payload.merge(
        'identifier' => @identifier,
        'exp' => @exp,
        'iat' => @iat,
      )
    end

    private
      def secret
        @secret ||= Slots.configuration.secret(@iat)
      end
      def encode(identifier)
        @identifier = identifier
        @exp = Slots.configuration.token_lifetime.from_now.to_i
        @iat = Time.now.to_i
        raise InvalidSecret if secret.nil?
        @token = JWT.encode self.payload, secret, 'HS256'
      end
      def decode(token)
        @token = token
        set_payload
        raise InvalidSecret if secret.nil?
        JWT.decode @token, secret, true, verify_iat: true, algorithm: 'HS256'
      end

      def set_payload
        encoded64 = @token.split('.')[1] || ''
        string_payload = Base64.decode64(encoded64)
        begin
          local_payload = JSON.parse(string_payload)
          raise JWT::DecodeError, 'Invalid Payload' unless local_payload.is_a?(Hash)
          @identifier = local_payload['identifier']
          @exp = local_payload['exp']&.to_i
          @iat = local_payload['iat']&.to_i
          @extra_payload = local_payload.except('identifier', 'exp', 'iat')
        rescue JSON::ParserError => e
          raise JWT::DecodeError, 'Invalid Payload'
        end
        # return invalid if exp isnt passed (this should only happen if the secret key is compromised...
        # which at that point you have other problems...)
        l = 3
        raise InvalidPayload, 'Payload is missing objects' unless payload.slice('identifier', 'exp', 'iat').compact.length == l
      end
  end
end
