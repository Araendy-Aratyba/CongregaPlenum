# frozen_string_literal: true

module CongregaPlenum
  # Service for voting records produced by the Chamber's Plenary and committees.
  #
  # A voting is a single, finished decision. It is not the legislative event in
  # which it occurred, and a proposition can be affected by several distinct
  # votings of amendments, reports, requests and other related propositions.
  # rubocop:disable Metrics/ClassLength
  class VotingsService
    # Maximum page size documented for the voting list endpoints.
    ITEMS_PER_PAGE = 100
    # Default ordering used by the official API.
    DEFAULT_ORDER = 'DESC'
    # Default field used by the official API to order voting records.
    DEFAULT_ORDER_BY = 'dataHoraRegistro'
    # Tag prefix for structured logging.
    SERVICE_TAG = 'CongregaPlenum::VotingsService'

    class << self
      # Shared client configured through {CongregaPlenum.configure}.
      #
      # @return [CongregaPlenum::Client]
      def client
        @client ||= CongregaPlenum::Client.instance
      end

      # Wraps {Client#get} with voting-specific logging while preserving errors.
      def api_get(endpoint, params = {})
        client.get(endpoint, params)
      rescue StandardError => e
        log_error("Erro ao acessar API em #{endpoint}: #{e.message}")
        raise
      end

      # Paginated variant of {.api_get}. Incomplete synchronizations are never
      # converted into empty results.
      def api_get_paginated(endpoint, params = {})
        client.get_paginated(endpoint, params)
      rescue StandardError => e
        log_error("Erro paginando API em #{endpoint}: #{e.message}")
        raise
      end

      # Retrieves all pages matching the supplied filters.
      #
      # Without date or identifier filters the Câmara API limits the result to
      # votings from the previous 30 days. When both dates are supplied they
      # must belong to the same calendar year, as required by the upstream API.
      #
      # @option filters [String,Integer,Array<String>,Array<Integer>] :voting_ids
      # @option filters [Integer,Array<Integer>] :proposition_ids
      # @option filters [Integer,Array<Integer>] :event_ids
      # @option filters [Integer,Array<Integer>] :body_ids identifiers from +/orgaos+
      # @option filters [String,Date] :start_date ISO 8601 date
      # @option filters [String,Date] :end_date ISO 8601 date
      # @option filters [String] :order +ASC+ or +DESC+
      # @option filters [String] :order_by field accepted by the upstream endpoint
      # @return [Array<Hash>]
      def fetch_all(**filters)
        log_info('Iniciando coleta de votações')

        filters[:items_per_page] = ITEMS_PER_PAGE
        votings = api_get_paginated('votacoes', list_params(filters))

        log_info("Coletamos #{votings.size} votações")
        votings
      end

      # Retrieves one page of basic voting records.
      #
      # @param page [Integer]
      # @param items_per_page [Integer]
      # @see .fetch_all for supported filters
      # @return [Array<Hash>]
      def fetch_list(page: 1, items_per_page: ITEMS_PER_PAGE, **filters)
        filters.merge!(page: page, items_per_page: items_per_page)
        params = list_params(filters)
        extract_collection(api_get('votacoes', params), 'lista de votações')
      end

      # Retrieves the detailed representation of a voting.
      #
      # The detail may contain possible voting objects and propositions affected
      # by the result. These relationships have different legislative meanings.
      #
      # @param voting_id [String,Integer] alphanumeric voting identifier
      # @return [Hash,nil]
      def fetch_by_id(voting_id)
        extract_detail(api_get("votacoes/#{voting_id}"), "votação #{voting_id}")
      end

      # Lists the individual positions registered in an open nominal voting.
      # An empty response does not identify absent deputies and is normal for
      # symbolic votings.
      #
      # @param voting_id [String,Integer]
      # @return [Array<Hash>]
      def fetch_votes(voting_id)
        response = api_get("votacoes/#{voting_id}/votos")
        extract_collection(response, "votos da votação #{voting_id}")
      end

      # Lists recommendations issued by parties, blocs and other leaderships.
      # The upstream API currently provides orientations only for Plenary votes.
      #
      # @param voting_id [String,Integer]
      # @return [Array<Hash>]
      def fetch_orientations(voting_id)
        response = api_get("votacoes/#{voting_id}/orientacoes")
        extract_collection(response, "orientações da votação #{voting_id}")
      end

      # Lists votings that had a proposition as their object or affected it.
      #
      # @param proposition_id [Integer]
      # @param order [String]
      # @param order_by [String]
      # @return [Array<Hash>]
      def fetch_by_proposition(proposition_id, order: DEFAULT_ORDER, order_by: DEFAULT_ORDER_BY)
        params = { ordem: order, ordenarPor: order_by }
        response = api_get("proposicoes/#{proposition_id}/votacoes", params)
        extract_collection(response, "votações da proposição #{proposition_id}")
      end

      # Lists votings completed during a deliberative event.
      #
      # @param event_id [Integer]
      # @return [Array<Hash>]
      def fetch_by_event(event_id)
        response = api_get("eventos/#{event_id}/votacoes")
        extract_collection(response, "votações do evento #{event_id}")
      end

      # Retrieves all voting pages for a Chamber body such as the Plenary or a
      # committee.
      #
      # @param body_id [Integer] identifier from +/orgaos+
      # @param proposition_ids [Integer,Array<Integer>,nil]
      # @param start_date [String,Date,nil]
      # @param end_date [String,Date,nil]
      # @param order [String]
      # @param order_by [String]
      # @return [Array<Hash>]
      # rubocop:disable Metrics/ParameterLists
      def fetch_by_body(body_id, proposition_ids: nil, start_date: nil, end_date: nil,
                        order: DEFAULT_ORDER, order_by: DEFAULT_ORDER_BY)
        params = {
          idProposicao: normalize_filter(proposition_ids),
          dataInicio: normalize_date(start_date),
          dataFim: normalize_date(end_date),
          itens: ITEMS_PER_PAGE,
          ordem: order,
          ordenarPor: order_by
        }.compact

        api_get_paginated("orgaos/#{body_id}/votacoes", params)
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def list_params(filters)
        identifiers = {
          id: normalize_filter(filters[:voting_ids]),
          idProposicao: normalize_filter(filters[:proposition_ids]),
          idEvento: normalize_filter(filters[:event_ids]),
          idOrgao: normalize_filter(filters[:body_ids]),
          dataInicio: normalize_date(filters[:start_date]),
          dataFim: normalize_date(filters[:end_date])
        }

        identifiers.merge(pagination_params(filters)).compact
      end

      def pagination_params(filters)
        {
          pagina: filters[:page],
          itens: filters.fetch(:items_per_page, ITEMS_PER_PAGE),
          ordem: filters.fetch(:order, DEFAULT_ORDER),
          ordenarPor: filters.fetch(:order_by, DEFAULT_ORDER_BY)
        }
      end

      def normalize_filter(value)
        return if value.nil?

        value.is_a?(Array) ? value.join(',') : value
      end

      def normalize_date(value)
        value&.to_s
      end

      def extract_detail(response, resource)
        detail = response['dados']
        return detail if detail.nil? || detail.is_a?(Hash)

        raise APIError, "Resposta inválida para #{resource}: esperado Hash ou nil em dados"
      end

      def extract_collection(response, resource)
        collection = response['dados']
        return [] if collection.nil?
        return collection if collection.is_a?(Array)

        raise APIError, "Resposta inválida para #{resource}: esperado Array ou nil em dados"
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
    end
  end
  # rubocop:enable Metrics/ClassLength
end
