# frozen_string_literal: true

module CongregaPlenum
  # HTTP client responsible for talking to the Câmara API endpoints and dealing
  # with retries, pagination and response parsing.
  #
  # All methods are thread-safe because the heavy collaborators ({HttpAdapter},
  # {RetryPolicy} and {ResponseHandler}) are stateless.
  class Client
    include Singleton

    attr_reader :http_adapter, :retry_policy, :response_handler

    def initialize
      configuration = CongregaPlenum.configuration
      @http_adapter = HttpAdapter.new(configuration: configuration)
      @retry_policy = RetryPolicy.new(configuration: configuration)
      @response_handler = ResponseHandler.new
    end

    # Performs a single HTTP GET to the given +endpoint+ and returns the parsed
    # JSON body.
    #
    # @param endpoint [String] the relative path (e.g. +deputados+)
    # @param params [Hash] query parameters merged into the request
    # @return [Hash] parsed response body
    def get(endpoint, params = {})
      url = build_url(endpoint, params)

      retry_policy.with_retries(url) { execute_request(url) }
    end

    # Retrieves all pages for an endpoint, flattening the +dados+ payloads into a
    # single array. Automatically respects the configured rate limit delay.
    #
    # @param endpoint [String]
    # @param params [Hash]
    # @return [Array<Hash>]
    def get_paginated(endpoint, params = {})
      # @type var results: Array[Hash[String, untyped]]
      results = []
      each_response_page(endpoint, params) { |page_data| results.concat(page_data) }

      results
    end

    private

    def each_response_page(endpoint, params)
      page = 1

      loop do
        response = request_page(endpoint, params, page)
        data = response.fetch('dados', [])
        break if data.empty?

        yield(data)
        break unless next_page?(response)

        page += 1
        apply_rate_limit_delay
      end
    end

    # Fetches a single page enforcing +formato=json+ and the requested page index.
    def request_page(endpoint, params, page)
      get(endpoint, params.merge(pagina: page, formato: 'json'))
    end

    def next_page?(response)
      response.fetch('links', []).any? { |link| link['rel'] == 'next' }
    end

    # Sleep between page fetches to respect the rate limit exposed by the API.
    # This is configurable because not every consumer has the same tolerance.
    def apply_rate_limit_delay
      delay = configuration.rate_limit_delay

      sleep(delay) if delay.positive?
    end

    def execute_request(url)
      response = http_adapter.get(url)

      response_handler.handle(response, url)
    end

    # Builds the full URL pointing to the Câmara API, ensuring +formato=json+ is present.
    #
    # @param endpoint [String]
    # @param params [Hash]
    # @return [String]
    def build_url(endpoint, params = {})
      uri = URI("#{configuration.base_url}/#{endpoint.gsub(%r{^/}, '')}")

      # Ensure formato=json is always present
      normalized_params = params.transform_keys(&:to_sym)
      normalized_params[:formato] ||= 'json'

      uri.query = URI.encode_www_form(normalized_params)

      uri.to_s
    end

    def configuration
      CongregaPlenum.configuration
    end
  end
end
