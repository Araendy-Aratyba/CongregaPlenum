# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

# rubocop:disable Metrics/BlockLength
RSpec.describe CongregaPlenum::VotingsService do
  let(:logger) { Logger.new(StringIO.new) }
  let(:configuration) { CongregaPlenum::Factories.configuration(logger: logger) }
  let(:client_double) { instance_double(CongregaPlenum::Client) }

  before do
    CongregaPlenum.configuration = configuration
    described_class.instance_variable_set(:@client, nil)
    allow(CongregaPlenum::Client).to receive(:instance).and_return(client_double)
  end

  describe '.fetch_all' do
    it 'pagina e converte filtros múltiplos para o formato aceito pela API' do
      voting = CongregaPlenum::Factories.voting_payload
      expect(client_double).to receive(:get_paginated).with(
        'votacoes',
        {
          idProposicao: '100,101',
          idOrgao: '180,200',
          dataInicio: '2026-01-01',
          dataFim: '2026-12-31',
          itens: described_class::ITEMS_PER_PAGE,
          ordem: described_class::DEFAULT_ORDER,
          ordenarPor: described_class::DEFAULT_ORDER_BY
        }
      ).and_return([voting])

      result = described_class.fetch_all(
        proposition_ids: [100, 101],
        body_ids: [180, 200],
        start_date: '2026-01-01',
        end_date: '2026-12-31'
      )

      expect(result).to eq([voting])
    end

    it 'propaga falhas para não devolver uma sincronização incompleta' do
      expect(client_double).to receive(:get_paginated).and_raise(CongregaPlenum::ConnectionError, 'offline')

      expect { described_class.fetch_all }.to raise_error(CongregaPlenum::ConnectionError, 'offline')
    end
  end

  describe '.fetch_list' do
    it 'retorna uma página sem buscar detalhes' do
      voting = CongregaPlenum::Factories.voting_payload
      expect(client_double).to receive(:get).with(
        'votacoes',
        {
          pagina: 2,
          itens: 50,
          ordem: 'ASC',
          ordenarPor: 'data'
        }
      ).and_return('dados' => [voting])

      expect(described_class.fetch_list(page: 2, items_per_page: 50, order: 'ASC', order_by: 'data')).to eq([voting])
    end
  end

  describe '.fetch_by_id' do
    it 'retorna o detalhe de uma votação alfanumérica' do
      detail = CongregaPlenum::Factories.voting_payload('objetosPossiveis' => [])
      expect(client_double).to receive(:get).with('votacoes/12345-2026', {}).and_return('dados' => detail)

      expect(described_class.fetch_by_id('12345-2026')).to eq(detail)
    end

    it 'rejeita um payload de detalhe contraditório' do
      expect(client_double).to receive(:get).and_return('dados' => [])

      expect { described_class.fetch_by_id('12345-2026') }
        .to raise_error(CongregaPlenum::APIError, /esperado Hash ou nil/)
    end
  end

  describe '.fetch_votes' do
    it 'retorna votos individuais e protege contra dados nulos' do
      expect(client_double).to receive(:get).with('votacoes/12345-2026/votos', {}).and_return('dados' => nil)

      expect(described_class.fetch_votes('12345-2026')).to eq([])
    end
  end

  describe '.fetch_orientations' do
    it 'retorna as orientações de bancada' do
      orientation = { 'siglaPartidoBloco' => 'ABC', 'orientacaoVoto' => 'Sim' }
      expect(client_double).to receive(:get)
        .with('votacoes/12345-2026/orientacoes', {})
        .and_return('dados' => [orientation])

      expect(described_class.fetch_orientations('12345-2026')).to eq([orientation])
    end
  end

  describe 'consultas relacionadas' do
    it 'consulta votações por proposição' do
      expect(client_double).to receive(:get).with(
        'proposicoes/100/votacoes',
        { ordem: 'DESC', ordenarPor: 'dataHoraRegistro' }
      ).and_return('dados' => [])

      expect(described_class.fetch_by_proposition(100)).to eq([])
    end

    it 'consulta votações por evento' do
      expect(client_double).to receive(:get).with('eventos/200/votacoes', {}).and_return('dados' => [])

      expect(described_class.fetch_by_event(200)).to eq([])
    end

    it 'pagina votações por órgão' do
      expect(client_double).to receive(:get_paginated).with(
        'orgaos/180/votacoes',
        {
          idProposicao: '100,101',
          dataInicio: '2026-01-01',
          dataFim: '2026-12-31',
          itens: described_class::ITEMS_PER_PAGE,
          ordem: described_class::DEFAULT_ORDER,
          ordenarPor: described_class::DEFAULT_ORDER_BY
        }
      ).and_return([])

      expect(
        described_class.fetch_by_body(
          180,
          proposition_ids: [100, 101],
          start_date: '2026-01-01',
          end_date: '2026-12-31'
        )
      ).to eq([])
    end
  end
end
# rubocop:enable Metrics/BlockLength
