# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Coverage badge generator' do
  let(:script) { File.expand_path('../../scripts/generate_coverage_badge.rb', __dir__) }

  it 'gera um endpoint Shields com a cobertura de linhas do SimpleCov' do
    Dir.mktmpdir do |directory|
      source = File.join(directory, 'last_run.json')
      destination = File.join(directory, 'coverage.json')
      File.write(source, JSON.generate('result' => { 'line' => 98.95, 'branch' => 86.66 }))

      _stdout, stderr, status = Open3.capture3(RbConfig.ruby, script, source, destination)

      expect(status).to be_success, stderr
      expect(JSON.parse(File.read(destination))).to eq(
        'schemaVersion' => 1,
        'label' => 'coverage',
        'message' => '98.95%',
        'color' => 'brightgreen'
      )
    end
  end

  it 'falha quando o resultado não contém cobertura de linhas' do
    Dir.mktmpdir do |directory|
      source = File.join(directory, 'last_run.json')
      destination = File.join(directory, 'coverage.json')
      File.write(source, JSON.generate('result' => {}))

      _stdout, stderr, status = Open3.capture3(RbConfig.ruby, script, source, destination)

      expect(status).not_to be_success
      expect(stderr).to include('Cobertura de linhas ausente')
      expect(File).not_to exist(destination)
    end
  end
end
# rubocop:enable Metrics/BlockLength
