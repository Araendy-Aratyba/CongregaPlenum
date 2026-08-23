# frozen_string_literal: true

module CongregaPlenum
  # Service responsible for interacting with congressmen endpoints, wrapping both
  # list and detail requests into high level helpers.
  class CongressmenService
    # Default page size for list endpoints.
    ITEMS_PER_PAGE = 100
    # Interval used to emit progress logs while iterating.
    PROGRESS_INTERVAL = 50
    # Tag prefix for structured logging.
    SERVICE_TAG = 'CongregaPlenum::CongressmenService'

    class << self
      # Shared client instance configured via {CongregaPlenum.configure}.
      #
      # @return [CongregaPlenum::Client]
      def client
        @client ||= CongregaPlenum::Client.instance
      end

      # Wraps {Client#get} to add service context without hiding request failures.
      def api_get(endpoint, params = {})
        client.get(endpoint, params)
      rescue StandardError => e
        log_error("Erro ao acessar API em #{endpoint}: #{e.message}")
        raise
      end

      # Same as {.api_get}, but for bulk pagination calls. Failures are propagated
      # so consumers can abort an incomplete synchronization.
      def api_get_paginated(endpoint, params = {})
        client.get_paginated(endpoint, params)
      rescue StandardError => e
        log_error("Erro paginando API em #{endpoint}: #{e.message}")
        raise
      end

      # Fetches the entire list of congressmen regardless of legislature.
      #
      # @return [Array<Hash>]
      def fetch_all
        fetch_deputies_collection(context: 'todos os deputados', params: { itens: ITEMS_PER_PAGE })
      end

      # Fetches all congressmen for a given legislature, enriching each entry with
      # its detailed payload.
      #
      # @param legislature_id [Integer]
      # @return [Array<Hash>]
      def fetch_all_by_legislature(legislature_id)
        fetch_deputies_collection(
          context: "legislatura #{legislature_id}",
          params: { itens: ITEMS_PER_PAGE, idLegislatura: legislature_id }
        )
      end

      # Retrieves the detailed payload of a single congressman.
      #
      # @param deputy_id [Integer]
      # @return [Hash, nil]
      # @raise [CongregaPlenum::APIError] if +dados+ has an unexpected type
      def fetch_by_id(deputy_id)
        log_debug("Buscando deputado #{deputy_id}")

        response = api_get("deputados/#{deputy_id}")
        extract_detail(response, "deputado #{deputy_id}")
      end

      # Returns a paginated list of congressmen straight from the API, without
      # making detail calls.
      #
      # @param page [Integer]
      # @param items_per_page [Integer]
      # @param legislature_id [Integer,nil]
      # @return [Array<Hash>]
      def fetch_list(page: 1, items_per_page: ITEMS_PER_PAGE, legislature_id: nil)
        log_debug("Buscando lista de deputados página #{page}")

        params = { pagina: page, itens: items_per_page }
        params[:idLegislatura] = legislature_id if legislature_id

        response = api_get('deputados', params)
        response['dados'] || []
      end

      private

      def extract_detail(response, resource)
        detail = response['dados']
        return detail if detail.nil? || detail.is_a?(Hash)

        raise APIError, "Resposta inválida para #{resource}: esperado Hash ou nil em dados"
      end

      # Coordinates pagination and detail fetches so the long running process can
      # log progress and reuse error handling in one place.
      def fetch_deputies_collection(context:, params:)
        log_info("Iniciando coleta de #{context}")

        deputies = api_get_paginated('deputados', params)

        log_info("Coletamos #{deputies.length} registros de #{context}")

        detailed_deputies = build_detailed_deputies(deputies, context)

        log_info("Finalizamos a coleta detalhada de #{detailed_deputies.length} registros para #{context}")
        detailed_deputies
      end

      # Walks the basic list and replaces each entry with its detailed payload.
      # Having this call separated from {#fetch_deputies_collection} keeps the
      # public method compact and enables targeted testing of the detail logic.
      def build_detailed_deputies(deputies, context)
        deputies.each_with_index.with_object([]) do |(deputy, index), collected|
          detailed_deputy = fetch_by_id(deputy['id'])
          collected << detailed_deputy if detailed_deputy
          log_progress(index, deputies.length, context)
        end
      end

      # Emits progress logs every {PROGRESS_INTERVAL} items so long running
      # synchronisations give users feedback without spamming the console.
      def log_progress(index, total, context)
        return unless ((index + 1) % PROGRESS_INTERVAL).zero?

        log_info("Processamos #{index + 1}/#{total} registros para #{context}")
      end

      def logger
        CongregaPlenum.configuration.logger
      end

      def log_info(message)
        logger.info("#{SERVICE_TAG}: #{message}")
      end

      def log_error(message)
        logger.error("#{SERVICE_TAG}: #{message}")
      end

      def log_debug(message)
        logger.debug("#{SERVICE_TAG}: #{message}")
      end
    end
  end
end
