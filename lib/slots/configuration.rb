# frozen_string_literal: true

module Slots
  class Configuration
    attr_accessor :login_regex_validations, :token_lifetime, :session_lifetime, :previous_jwt_lifetime
    attr_reader :logins
    attr_writer :authentication_model
    def initialize
      @logins = {email: //}
      @login_regex_validations = true
      @authentication_model = 'User'
      @secret_keys = [{created_at: 0, secret: ENV['SLOT_SECRET']}]
      @token_lifetime = 1.hour
      @session_lifetime = 2.weeks # Set to nil if you dont want sessions
      @previous_jwt_lifetime = 5.seconds # Set to nil if you dont want sessions
      @manage_callbacks = Proc.new { }
    end

    def logins=(value)
      if value.is_a? Symbol
        @logins = {value => //}
      elsif value.is_a?(Hash)
        # Should do most inclusive regex last
        raise 'must be hash of symbols => regex' unless value.length > 0 && value.all? { |k, v| k.is_a?(Symbol) && v.is_a?(Regexp) }
        @logins = value
      else
        raise 'must be a symbol or hash'
      end
    end

    def authentication_model
      @authentication_model.to_s.constantize rescue nil
    end

    def secret=(v)
      @secret_keys = [{created_at: 0, secret: v}]
    end

    def secret(at = Time.now.to_i)
      @secret_keys.each do |secret_hash|
        return secret_hash[:secret] if at > secret_hash[:created_at]
      end
      raise InvalidSecret
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
