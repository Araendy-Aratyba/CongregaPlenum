# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

# rubocop:disable Metrics/BlockLength
RSpec.describe CongregaPlenum::CongressmenService do
  let(:logger) { Logger.new(StringIO.new) }
  let(:configuration) { CongregaPlenum::Factories.configuration(logger: logger) }
  let(:client_double) { instance_double(CongregaPlenum::Client) }

  before do
    CongregaPlenum.configuration = configuration
    described_class.instance_variable_set(:@client, nil)
    allow(CongregaPlenum::Client).to receive(:instance).and_return(client_double)
  end

  describe '.fetch_list' do
    it 'inclui parametros de pagina e legislatura quando informada' do
      payload = CongregaPlenum::Factories.deputy_payload
      expect(client_double).to receive(:get)
        .with('deputados', { pagina: 3, itens: 20, idLegislatura: 56 })
        .and_return('dados' => [payload])

      expect(described_class.fetch_list(page: 3, items_per_page: 20, legislature_id: 56)).to eq([payload])
    end
  end

  describe '.fetch_all_by_legislature' do
    it 'retorna detalhes de cada deputado' do
      list = [
        CongregaPlenum::Factories.deputy_payload('id' => 1),
        CongregaPlenum::Factories.deputy_payload('id' => 2)
      ]

      expect(client_double).to receive(:get_paginated)
        .with('deputados', { itens: CongregaPlenum::CongressmenService::ITEMS_PER_PAGE, idLegislatura: 60 })
        .and_return(list)

      expect(client_double).to receive(:get).with('deputados/1', {}).and_return('dados' => { 'id' => 1 })
      expect(client_double).to receive(:get).with('deputados/2', {}).and_return('dados' => { 'id' => 2 })

      expect(described_class.fetch_all_by_legislature(60)).to eq([{ 'id' => 1 }, { 'id' => 2 }])
    end

    it 'ignora registros sem detalhes' do
      list = [
        CongregaPlenum::Factories.deputy_payload('id' => 5),
        CongregaPlenum::Factories.deputy_payload('id' => 6)
      ]

      expect(client_double).to receive(:get_paginated)
        .with('deputados', { itens: CongregaPlenum::CongressmenService::ITEMS_PER_PAGE, idLegislatura: 60 })
        .and_return(list)

      expect(client_double).to receive(:get).with('deputados/5', {}).and_return('dados' => nil)
      expect(client_double).to receive(:get).with('deputados/6', {}).and_return('dados' => { 'id' => 6 })

      expect(described_class.fetch_all_by_legislature(60)).to eq([{ 'id' => 6 }])
    end
  end

  describe '.fetch_by_id' do
    it 'propaga a falha da API' do
      expect(client_double).to receive(:get).and_raise(CongregaPlenum::APIError, 'falha')

      expect { described_class.fetch_by_id(5) }.to raise_error(CongregaPlenum::APIError, 'falha')
    end
  end

  describe '.fetch_all' do
    it 'propaga falhas de paginação em vez de retornar uma sincronização vazia' do
      expect(client_double).to receive(:get_paginated).and_raise(CongregaPlenum::ConnectionError, 'offline')

      expect { described_class.fetch_all }.to raise_error(CongregaPlenum::ConnectionError, 'offline')
    end
  end

  describe '.log_progress' do
    it 'emite log quando o intervalo é alcançado' do
      expect(described_class).to receive(:log_info).with(include('Processamos')).and_call_original

      described_class.send(
        :log_progress,
        CongregaPlenum::CongressmenService::PROGRESS_INTERVAL - 1,
        100,
        'contexto teste'
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
