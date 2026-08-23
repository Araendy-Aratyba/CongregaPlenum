# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CongregaPlenum::LegislaturesService do
  before do
    CongregaPlenum.configuration = CongregaPlenum::Configuration.new
    CongregaPlenum::Factories.reset_client_singleton
    described_class.instance_variable_set(:@client, nil)
  end

  describe '.fetch_deputies' do
    it 'consulta deputados usando o filtro oficial de legislatura' do
      request = stub_request(:get, %r{/deputados\?})
                .with(query: hash_including(idLegislatura: '57', itens: '100'))
                .to_return(
                  status: 200,
                  body: {
                    dados: [{ 'id' => 1 }],
                    links: []
                  }.to_json
                )

      expect(described_class.fetch_deputies(57)).to eq([{ 'id' => 1 }])
      expect(request).to have_been_requested.once
      expect(a_request(:get, %r{/legislaturas/57/deputados})).not_to have_been_made
    end
  end
end
