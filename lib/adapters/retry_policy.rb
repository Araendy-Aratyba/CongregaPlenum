# frozen_string_literal: true

module CongregaPlenum
  # Controls retry attempts with exponential backoff and jitter.
  class RetryPolicy
    def initialize(configuration: CongregaPlenum.configuration)
      @configuration = configuration
    end

    # Wraps a block with retry logic for transient network/API errors.
    #
    # @param url [String] identifier used for logging
    # @yieldreturn [Object] result of the successful request
    def with_retries(url)
      retries = 0
      begin
        yield
      rescue ConnectionError, RateLimitError, ServerError => e
        retries += 1
        return handle_retry_failure(url, e) if retries > max_retries

        retry_request(retries, url, e)
        retry
      end
    end

    private

    attr_reader :configuration

    # Logs the retry attempt and sleeps according to the backoff algorithm. In
    # tests we stub this to keep them fast/deterministic.
    def retry_request(retry_count, url, error)
      delay = calculate_backoff_delay(retry_count)

      logger.warn(
        "CongregaPlenum: Tentativa #{retry_count}/#{max_retries} para #{url}: #{error.message}, aguardando #{delay}s"
      )
      sleep(delay)
    end

    # Emits the failure message and re-raises so the caller pode decidir se trata ou não.
    def handle_retry_failure(url, error)
      logger.error(
        "CongregaPlenum: Falha após #{max_retries} tentativas para #{url}: #{error.message}"
      )

      raise error
    end

    # Calculates the exponential backoff delay with jitter to avoid thundering
    # herds when several workers hit the same failure simultaneously.
    def calculate_backoff_delay(retry_count)
      base_delay = configuration.retry_delay
      jitter = rand(0.5..1.5).to_f

      [base_delay * (2**(retry_count - 1)) * jitter, 30.0].min
    end

    def max_retries
      configuration.retries
    end

    def logger
      configuration.logger
    end
  end
end
