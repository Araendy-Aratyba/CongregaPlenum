# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Release workflow' do
  let(:workflow) do
    YAML.safe_load_file(File.expand_path('../../.github/workflows/release.yml', __dir__), aliases: true)
  end
  let(:trigger) { workflow['on'] || workflow.fetch(true) }
  let(:steps) { workflow.dig('jobs', 'push-gem', 'steps') }

  def step_named(name)
    steps.find { |step| step['name'] == name }
  end

  it 'exige o tag solicitado e faz checkout dessa referência sem persistir credenciais' do
    tag_input = trigger.dig('workflow_dispatch', 'inputs', 'tag')
    checkout = step_named('Checkout')

    expect(tag_input).to include('required' => true, 'type' => 'string')
    expect(checkout.fetch('with')).to include(
      'ref' => '${{ inputs.tag }}',
      'persist-credentials' => false
    )
  end

  it 'valida o tag por variável de ambiente antes de construir a gem' do
    validation = step_named('Validate requested release')

    expect(validation.dig('env', 'RELEASE_TAG')).to eq('${{ inputs.tag }}')
    expect(validation.fetch('run')).to include('expected_tag="v${version}"', 'git describe --tags --exact-match HEAD')
    expect(validation.fetch('run')).not_to include('${{ inputs.tag }}')
  end

  it 'publica apenas o artefato validado pelo passo de build' do
    build = step_named('Build gem')
    push = step_named('Push to RubyGems')

    expect(build.fetch('id')).to eq('build')
    expect(build.fetch('run')).to include('gem_file="pkg/congrega_plenum-${version}.gem"')
    expect(push.dig('env', 'GEM_FILE')).to eq('${{ steps.build.outputs.gem_path }}')
    expect(push.fetch('run')).to eq('gem push "$GEM_FILE" --host https://rubygems.org')
    expect(push.fetch('run')).not_to include('*.gem')
  end

  it 'autentica no RubyGems com o secret protegido do ambiente de release' do
    credentials = step_named('Configure RubyGems credentials')
    push = step_named('Push to RubyGems')

    expect(workflow.fetch('permissions')).to eq('contents' => 'read')
    expect(workflow.dig('jobs', 'push-gem', 'environment')).to eq('release')
    expect(credentials.fetch('uses')).to eq(
      'rubygems/configure-rubygems-credentials@dc5a8d8553e6ee01fc26761a49e99e733d17954a'
    )
    expect(credentials.fetch('with')).to eq(
      'api-token' => '${{ secrets.RUBYGEMS_API_TOKEN }}'
    )
    expect(push.fetch('env')).not_to have_key('GEM_HOST_API_KEY')
    workflow_source = File.read(File.expand_path('../../.github/workflows/release.yml', __dir__))
    expect(workflow_source).not_to include('rubygems_')
  end
end
# rubocop:enable Metrics/BlockLength
