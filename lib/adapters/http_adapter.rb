# frozen_string_literal: true

module CongregaPlenum
  # Encapsulates Net::HTTP details and shared configuration. Centralising the
  # HTTP wiring keeps the client implementation focused on retries and parsing.
  class HttpAdapter
    # Creates a new adapter using the provided configuration. Injecting the
    # configuration makes it trivial to plug test doubles or tweak settings when
    # using multiple clients simultaneously.
    def initialize(configuration: CongregaPlenum.configuration)
      @configuration = configuration
    end

    # Executes a GET request and returns the raw {::Net::HTTPResponse}. All network
    # errors of interest are mapped to {CongregaPlenum::ConnectionError} so upper
    # layers can treat them uniformly.
    def get(url)
      uri = URI(url)
      http = build_http_client(uri)
      request = build_http_request(uri)

      logger.debug("CongregaPlenum: Requisição GET para #{url}")
      http.request(request)
    rescue Timeout::Error, SocketError, Errno::ECONNRESET => e
      raise ConnectionError, "Connection failed for #{url}: #{e.message}"
    end

    private

    attr_reader :configuration

    # Builds the configured Net::HTTP client honoring SSL and timeouts. Keeping
    # this logic here avoids repetition if a different adapter is introduced.
    def build_http_client(uri)
      host = uri.host
      raise URI::InvalidURIError, 'HTTP URL must include a host' unless host

      Net::HTTP.new(host, uri.port).tap do |http|
        http.use_ssl = uri.scheme == 'https'
        timeout = configuration.timeout
        http.read_timeout = timeout
        http.open_timeout = timeout
      end
    end

    # Prepares a GET request with headers that make the API happy (user agent and
    # content type). Any change requested by the Câmara ficará concentrada aqui.
    def build_http_request(uri)
      Net::HTTP::Get.new(uri).tap do |request|
        request['User-Agent'] = 'CongregaPlenum/1.0'
        request['Accept'] = 'application/json'
      end
    end

    def logger
      configuration.logger
    end
  end
end
