# frozen_string_literal: true

require_relative 'version'

require 'net/http'
require 'json'
require 'uri'
require 'singleton'
require 'logger'

# CongregaPlenum centralizes access to the Brazilian Chamber of Deputies public API.
# It exposes a global configuration and service objects for each resource.
module CongregaPlenum
  # Base error class for all domain-specific exceptions in the gem.
  class Error < StandardError; end
  # Raised when connectivity fails before receiving a valid HTTP response.
  class ConnectionError < Error; end
  # Raised when the API responds with an unexpected status code or payload.
  class APIError < Error; end
  # Raised for transient 5xx responses that are safe to retry.
  class ServerError < APIError; end
  # Raised when the API signals that the rate limit has been exceeded.
  class RateLimitError < Error; end

  class << self
    attr_accessor :configuration
  end

  # Yields the current {Configuration} so callers can override defaults.
  #
  # @yieldparam config [Configuration] the mutable configuration object
  def self.configure
    self.configuration ||= Configuration.new

    yield(configuration)
  end

  # Shared configuration used by the client and services to tweak base URL,
  # timeouts and retry policies. Defaults focus on the public APIs hosted by the
  # Câmara so a regular application can simply call {CongregaPlenum.configure} and
  # override what differs (timeouts, logger, etc.).
  class Configuration
    # @return [String] Base endpoint for all requests.
    attr_accessor :base_url
    # @return [Integer] Timeout (seconds) applied to open/read operations.
    attr_accessor :timeout
    # @return [Integer] How many times requests are retried on transient errors.
    attr_accessor :retries
    # @return [Float] Initial backoff delay in seconds.
    attr_accessor :retry_delay
    # @return [Float] Delay between paginated calls to respect rate limits.
    attr_accessor :rate_limit_delay
    # @return [Logger] Logger used across adapters/services.
    attr_accessor :logger

    # Builds a configuration instance with safe defaults tuned for the Câmara APIs.
    # Those endpoints are known to be HTTPS-only, relatively slow, and rate-limited,
    # so the defaults try to smooth that out.
    def initialize
      @base_url = 'https://dadosabertos.camara.leg.br/api/v2'
      @timeout = 30
      @retries = 3
      @retry_delay = 1.0
      @rate_limit_delay = 0.1
      @logger = Logger.new($stdout)
    end
  end

  # Initialize with default configuration
  configure do |_config|
    # Defaults are already set in Configuration#initialize
  end
end

# Load all sub-modules
require_relative 'adapters/http_adapter'
require_relative 'adapters/retry_policy'
require_relative 'adapters/response_handler'
require_relative 'client'
require_relative 'modules/congressmen_service'
require_relative 'modules/parties_service'
require_relative 'modules/legislatures_service'
