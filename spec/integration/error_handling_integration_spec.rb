# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Error handling integration' do
  it 'repete 429 e levanta RateLimitError após esgotar as tentativas' do
    stub_request(:get, %r{/deputados})
      .to_return(status: 429, body: { erros: [] }.to_json)

    configuration = CongregaPlenum::Factories.configuration(retries: 1, retry_delay: 0)
    client = CongregaPlenum::Factories.client(configuration: configuration)

    expect { client.get('deputados') }.to raise_error(CongregaPlenum::RateLimitError)
    expect(a_request(:get, %r{/deputados})).to have_been_made.twice
  end

  it 'não repete 404' do
    stub_request(:get, %r{/deputados/999})
      .to_return(status: 404, body: { erros: [] }.to_json)

    configuration = CongregaPlenum::Factories.configuration(retries: 3, retry_delay: 0)
    client = CongregaPlenum::Factories.client(configuration: configuration)

    expect { client.get('deputados/999') }.to raise_error(CongregaPlenum::APIError)
    expect(a_request(:get, %r{/deputados/999})).to have_been_made.once
  end
end
