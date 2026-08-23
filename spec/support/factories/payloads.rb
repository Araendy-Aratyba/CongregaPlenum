# frozen_string_literal: true

module CongregaPlenum
  module Factories
    module_function

    def api_response(dados: [], links: [])
      { 'dados' => dados, 'links' => links }
    end

    def paginated_response(dados:, next_link: nil)
      links = []
      links << { 'rel' => 'next', 'href' => next_link } if next_link

      api_response(dados: dados, links: links)
    end

    def deputy_payload(overrides = {})
      {
        'id' => 1,
        'nome' => 'Deputado Um',
        'siglaPartido' => 'ABC',
        'siglaUf' => 'DF'
      }.merge(overrides)
    end

    def party_payload(overrides = {})
      {
        'id' => 10,
        'sigla' => 'XYZ',
        'nome' => 'Partido XYZ'
      }.merge(overrides)
    end

    def legislature_payload(overrides = {})
      {
        'id' => 100,
        'dataInicio' => '2023-02-01',
        'dataFim' => '2026-01-31'
      }.merge(overrides)
    end

    def voting_payload(overrides = {})
      {
        'id' => '12345-2026',
        'data' => '2026-08-20',
        'descricao' => 'Aprovado o parecer.',
        'aprovacao' => 1,
        'siglaOrgao' => 'PLEN'
      }.merge(overrides)
    end
  end
end
