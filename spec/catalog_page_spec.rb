# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CongregaPlenum::CatalogPage do # rubocop:disable Metrics/BlockLength
  let(:base) { CongregaPlenum.configuration.base_url }
  let(:entries) { [{ 'id' => 17, 'siglaPartido' => 'ABC' }, { 'id' => 17, 'siglaPartido' => 'DEF' }] }
  let(:next_link) { { 'rel' => 'next', 'href' => 'https://example.org/deputados?pagina=6' } }

  it 'keeps distinct rows for the same deputy and continues even on a short page' do
    stub_request(:get, "#{base}/deputados")
      .with(query: { idLegislatura: 56, itens: 100, ordem: 'ASC', ordenarPor: 'id', pagina: 5, formato: 'json' })
      .to_return(body: JSON.generate('dados' => entries, 'links' => [next_link]))

    page = CongregaPlenum::CongressmenService.fetch_page(page: 5, legislature_id: 56)

    expect(page).to have_attributes(records: entries, next_page: 6)
  end

  it 'acknowledges explicit empty final pages' do
    stub_request(:get, "#{base}/partidos")
      .with(query: { itens: 100, ordem: 'ASC', ordenarPor: 'id', pagina: 1, formato: 'json' })
      .to_return(body: JSON.generate('dados' => [], 'links' => []))

    expect(CongregaPlenum::PartiesService.fetch_page).to have_attributes(records: [], next_page: nil)
  end

  it 'validates legislatures without requiring a continuation on the final page' do
    rows = [{ 'id' => 57 }]
    stub_request(:get, "#{base}/legislaturas")
      .with(query: { itens: 50, pagina: 1, formato: 'json' })
      .to_return(body: JSON.generate('dados' => rows, 'links' => [{ 'rel' => 'self' }]))

    expect(CongregaPlenum::LegislaturesService.fetch_page).to have_attributes(records: rows, next_page: nil)
  end

  it 'fails on incomplete data and malformed continuation' do
    invalid_responses = [
      { 'links' => [] }, { 'dados' => nil, 'links' => [] }, { 'dados' => entries },
      { 'dados' => entries, 'links' => [next_link, next_link] },
      { 'dados' => [], 'links' => [next_link] },
      { 'dados' => entries, 'links' => [{ 'rel' => 'next', 'href' => 'https://example.org/deputados?pagina=5' }] }
    ]
    invalid_responses.each do |response|
      expect { described_class.parse(response, page: 5) }.to raise_error(CongregaPlenum::APIError)
    end
  end
end
