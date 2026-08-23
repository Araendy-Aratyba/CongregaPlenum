# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

# rubocop:disable Metrics/BlockLength
RSpec.describe CongregaPlenum::LegislaturesService do
  let(:logger) { Logger.new(StringIO.new) }
  let(:configuration) { CongregaPlenum::Factories.configuration(logger: logger) }
  let(:client_double) { instance_double(CongregaPlenum::Client) }

  before do
    CongregaPlenum.configuration = configuration
    described_class.instance_variable_set(:@client, nil)
    allow(CongregaPlenum::Client).to receive(:instance).and_return(client_double)
  end

  describe '.fetch_all' do
    it 'propaga lista paginada' do
      payload = [CongregaPlenum::Factories.legislature_payload]
      expect(client_double).to receive(:get_paginated)
        .with('legislaturas', { itens: CongregaPlenum::LegislaturesService::PAGE_SIZE })
        .and_return(payload)

      expect(described_class.fetch_all).to eq(payload)
    end
  end

  describe '.fetch_mesa' do
    it 'retorna conjunto protegido contra nil' do
      expect(client_double).to receive(:get).with('legislaturas/58/mesa', {}).and_return('dados' => nil)

      expect(described_class.fetch_mesa(58)).to eq([])
    end
  end

  describe '.fetch_deputies' do
    it 'filtra o endpoint de deputados pela legislatura' do
      deputies = [CongregaPlenum::Factories.deputy_payload]
      expect(client_double).to receive(:get_paginated)
        .with(
          'deputados',
          {
            itens: CongregaPlenum::LegislaturesService::DEPUTIES_PAGE_SIZE,
            idLegislatura: 59
          }
        )
        .and_return(deputies)

      expect(described_class.fetch_deputies(59)).to eq(deputies)
    end
  end

  describe '.fetch_by_id' do
    it 'retorna array vazio quando api falha' do
      allow(client_double).to receive(:get).and_raise(StandardError, 'oops')

      expect(described_class.fetch_by_id(60)).to eq([])
    end
  end
end
# rubocop:enable Metrics/BlockLength
