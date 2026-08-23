# frozen_string_literal: true

module CongregaPlenum
  # Service responsible for interacting with party endpoints. It exposes class
  # methods that hide pagination, retries and detail lookups.
  class PartiesService
    # Default page size for party listings.
    ITEMS_PER_PAGE = 100
    # Interval used to emit progress logs while iterating.
    PROGRESS_INTERVAL = 20
    # Tag prefix for structured logging.
    SERVICE_TAG = 'CongregaPlenum::PartiesService'

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

      # Bulk variant of {.api_get}. Failures are propagated so consumers can
      # abort an incomplete synchronization.
      def api_get_paginated(endpoint, params = {})
        client.get_paginated(endpoint, params)
      rescue StandardError => e
        log_error("Erro paginando API em #{endpoint}: #{e.message}")
        raise
      end

      # Fetches every party registered na API, enriquecendo com payload detalhado.
      #
      # @return [Array<Hash>]
      def fetch_all
        log_info('Iniciando coleta de todos os partidos')

        parties = api_get_paginated('partidos', itens: ITEMS_PER_PAGE)

        log_info("Coletamos #{parties.length} partidos da listagem")

        detailed_parties = build_detailed_parties(parties)

        log_info("Finalizamos a coleta detalhada de #{detailed_parties.length} partidos")
        detailed_parties
      end

      # Retrieves the detailed payload for a single party.
      #
      # @param party_id [Integer]
      # @return [Hash,nil]
      def fetch_by_id(party_id)
        log_debug("Buscando partido #{party_id}")

        response = api_get("partidos/#{party_id}")
        response['dados']
      end

      # Returns a paginated list of parties, without triggering detail lookups.
      #
      # @param page [Integer]
      # @param items_per_page [Integer]
      # @return [Array<Hash>]
      def fetch_list(page: 1, items_per_page: ITEMS_PER_PAGE)
        log_debug("Buscando lista de partidos página #{page}")

        response = api_get('partidos', pagina: page, itens: items_per_page)
        response['dados'] || []
      end

      private

      # Converts the lightweight list into the detailed payload expected by
      # consumers. Extracted to simplify instrumentation/tests.
      def build_detailed_parties(parties)
        parties.each_with_index.with_object([]) do |(party, index), collected|
          detailed_party = fetch_by_id(party['id'])
          collected << detailed_party if detailed_party
          log_progress(index, parties.length)
        end
      end

      # Emits periodic progress updates so users know long iterations are still
      # alive.
      def log_progress(index, total)
        return unless ((index + 1) % PROGRESS_INTERVAL).zero?

        log_info("Processamos #{index + 1}/#{total} partidos")
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
