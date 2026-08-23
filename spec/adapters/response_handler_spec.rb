# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe CongregaPlenum::ResponseHandler do
  subject(:handler) { described_class.new }

  let(:response) { instance_double(Net::HTTPResponse, code: code, message: 'OK', body: body) }
  let(:code) { '200' }
  let(:body) { '{"dados":[]}' }

  describe '#handle' do
    it 'retorna o JSON parseado quando status 200' do
      expect(handler.handle(response, 'url')).to eq('dados' => [])
    end

    context 'quando API retorna 429' do
      let(:code) { '429' }

      it 'lança erro específico de rate limit' do
        expect { handler.handle(response, 'url') }.to raise_error(CongregaPlenum::RateLimitError)
      end
    end

    context 'quando JSON é inválido' do
      let(:body) { 'invalid' }

      it 'lança CongregaPlenum::APIError' do
        expect { handler.handle(response, 'url') }.to raise_error(CongregaPlenum::APIError)
      end
    end

    context 'quando o JSON de topo não é um objeto' do
      let(:code) { '200' }
      let(:body) { [{ id: 1 }].to_json }

      it 'lança CongregaPlenum::APIError' do
        expect { handler.handle(response, 'url') }
          .to raise_error(CongregaPlenum::APIError, /expected an object/)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
