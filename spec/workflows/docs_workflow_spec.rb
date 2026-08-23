# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Docs workflow' do
  let(:workflow) do
    YAML.safe_load_file(File.expand_path('../../.github/workflows/docs.yml', __dir__), aliases: true)
  end
  let(:job) { workflow.dig('jobs', 'deploy') }
  let(:steps) { job.fetch('steps') }

  it 'concede somente as permissões necessárias para o GitHub Pages' do
    expect(workflow.fetch('permissions')).to eq(
      'contents' => 'read',
      'pages' => 'write',
      'id-token' => 'write'
    )
    expect(job.fetch('environment')).to include('name' => 'github-pages')
  end

  it 'gera e publica a documentação como artefato oficial do Pages' do
    actions = steps.filter_map { |step| step['uses'] }

    expect(actions).to include(
      'actions/configure-pages@v6',
      'actions/upload-pages-artifact@v5',
      'actions/deploy-pages@v5'
    )
    expect(steps.find { |step| step['uses'] == 'actions/upload-pages-artifact@v5' }.fetch('with'))
      .to eq('path' => './doc')
  end

  it 'publica o endpoint do badge após calcular a cobertura' do
    commands = steps.filter_map { |step| step['run'] }

    expect(commands).to include(
      'bundle exec rspec',
      'bundle exec ruby scripts/generate_coverage_badge.rb'
    )

    badge_step = steps.index { |step| step['run'] == 'bundle exec ruby scripts/generate_coverage_badge.rb' }
    upload_step = steps.index { |step| step['uses'] == 'actions/upload-pages-artifact@v5' }

    expect(badge_step).to be < upload_step
  end
end
# rubocop:enable Metrics/BlockLength
