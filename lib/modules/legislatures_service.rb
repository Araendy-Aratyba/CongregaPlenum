# frozen_string_literal: true

module CongregaPlenum
  # Service responsible for interacting with legislature endpoints including mesa
  # composition and deputies per legislature.
  class LegislaturesService
    # Default pagination size for legislature listings.
    PAGE_SIZE = 50
    # Pagination size for deputies per legislature.
    DEPUTIES_PAGE_SIZE = 100
    # Tag prefix for structured logging.
    SERVICE_TAG = 'CongregaPlenum::LegislaturesService'

    class << self
      # Shared client instance configured via {CongregaPlenum.configure}.
      #
      # @return [CongregaPlenum::Client]
      def client
        @client ||= CongregaPlenum::Client.instance
      end

      # Resilient wrapper around {Client#get} guaranteeing callers always receive
      # a predictable structure even when the API misbehaves.
      def api_get(endpoint, params = {})
        client.get(endpoint, params)
      rescue StandardError => e
        log_error("Erro ao acessar API em #{endpoint}: #{e.message}")
        { 'dados' => [] }
      end

      # Bulk variant of {.api_get} protecting pagination loops.
      def api_get_paginated(endpoint, params = {})
        client.get_paginated(endpoint, params)
      rescue StandardError => e
        log_error("Erro paginando API em #{endpoint}: #{e.message}")
        []
      end

      # Returns every legislature exposed by a API.
      #
      # @return [Array<Hash>]
      def fetch_all
        log_info('Iniciando busca de todas as legislaturas')

        legislatures = api_get_paginated('legislaturas', itens: PAGE_SIZE)

        log_info("Total de #{legislatures.size} legislaturas encontradas")
        legislatures
      rescue StandardError => e
        log_error("Erro ao buscar legislaturas: #{e.message}")
        []
      end

      # Fetches a single legislature payload.
      #
      # @param legislature_id [Integer]
      # @return [Hash,nil]
      def fetch_by_id(legislature_id)
        log_debug("Buscando legislatura #{legislature_id}")

        response = api_get("legislaturas/#{legislature_id}")
        response['dados']
      rescue StandardError => e
        log_error("Erro ao buscar legislatura #{legislature_id}: #{e.message}")
        nil
      end

      # Retrieves the mesa composition for the provided legislature ID.
      #
      # @param legislature_id [Integer]
      # @return [Array<Hash>]
      def fetch_mesa(legislature_id)
        response = api_get("legislaturas/#{legislature_id}/mesa")
        mesa_data = response['dados'] || []

        log_info("Mesa da legislatura #{legislature_id} coletada com #{mesa_data.size} integrantes")
        mesa_data
      rescue StandardError => e
        log_error("Erro ao buscar mesa da legislatura #{legislature_id}: #{e.message}")
        []
      end

      # Lists every deputy that served/serves in the given legislature using the
      # +idLegislatura+ filter supported by the deputies endpoint.
      #
      # @param legislature_id [Integer]
      # @return [Array<Hash>]
      def fetch_deputies(legislature_id)
        log_info("Iniciando coleta de deputados da legislatura #{legislature_id}")

        deputies = api_get_paginated('deputados', itens: DEPUTIES_PAGE_SIZE, idLegislatura: legislature_id)

        log_info("Coletamos #{deputies.size} deputados para a legislatura #{legislature_id}")
        deputies
      rescue StandardError => e
        log_error("Erro ao buscar deputados da legislatura #{legislature_id}: #{e.message}")
        []
      end

      private

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
