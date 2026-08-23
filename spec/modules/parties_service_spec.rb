# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

# rubocop:disable Metrics/BlockLength
RSpec.describe CongregaPlenum::PartiesService do
  let(:logger) { Logger.new(StringIO.new) }
  let(:configuration) { CongregaPlenum::Factories.configuration(logger: logger) }
  let(:client_double) { instance_double(CongregaPlenum::Client) }

  before do
    CongregaPlenum.configuration = configuration
    described_class.instance_variable_set(:@client, nil)
    allow(CongregaPlenum::Client).to receive(:instance).and_return(client_double)
  end

  describe '.fetch_list' do
    it 'retorna os dados crus da API' do
      payload = CongregaPlenum::Factories.party_payload
      expect(client_double).to receive(:get)
        .with('partidos', { pagina: 2, itens: 50 })
        .and_return('dados' => [payload])

      expect(described_class.fetch_list(page: 2, items_per_page: 50)).to eq([payload])
    end
  end

  describe '.fetch_all' do
    it 'realiza paginação e busca detalhes' do
      list = [
        CongregaPlenum::Factories.party_payload('id' => 10),
        CongregaPlenum::Factories.party_payload('id' => 11)
      ]

      expect(client_double).to receive(:get_paginated)
        .with('partidos', { itens: CongregaPlenum::PartiesService::ITEMS_PER_PAGE })
        .and_return(list)

      expect(client_double).to receive(:get).with('partidos/10', {}).and_return('dados' => { 'id' => 10 })
      expect(client_double).to receive(:get).with('partidos/11', {}).and_return('dados' => { 'id' => 11 })

      expect(described_class.fetch_all).to eq([{ 'id' => 10 }, { 'id' => 11 }])
    end
  end

  describe '.fetch_by_id' do
    it 'propaga a falha da API' do
      expect(client_double).to receive(:get).and_raise(CongregaPlenum::APIError, 'erro')

      expect { described_class.fetch_by_id(10) }.to raise_error(CongregaPlenum::APIError, 'erro')
    end
  end

  describe '.fetch_all quando a API falha' do
    it 'propaga a falha em vez de retornar uma sincronização vazia' do
      expect(client_double).to receive(:get_paginated).and_raise(CongregaPlenum::ConnectionError, 'offline')

      expect { described_class.fetch_all }.to raise_error(CongregaPlenum::ConnectionError, 'offline')
    end
  end

  describe '.log_progress' do
    it 'loga a cada intervalo' do
      expect(described_class).to receive(:log_info).with(include('Processamos')).and_call_original

      described_class.send(
        :log_progress,
        CongregaPlenum::PartiesService::PROGRESS_INTERVAL - 1,
        40
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
