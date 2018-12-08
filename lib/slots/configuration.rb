# frozen_string_literal: true

module Slots
  class Configuration
    attr_accessor :login_regex_validations
    attr_reader :logins
    def initialize
      @logins = {email: //}
      @login_regex_validations = true
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
