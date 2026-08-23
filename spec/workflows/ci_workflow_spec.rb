# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'CI workflow' do
  let(:workflow) do
    YAML.safe_load_file(File.expand_path('../../.github/workflows/ci.yml', __dir__), aliases: true)
  end
  let(:steps) { workflow.dig('jobs', 'test', 'steps') }

  it 'valida código, tipos, testes, documentação e o pacote da gem' do
    commands = steps.filter_map { |step| step['run'] }

    expect(commands).to include(
      'bundle exec rubocop',
      'bundle exec steep check',
      'bundle exec rspec',
      'bundle exec yard stats --list-undoc',
      'bundle exec rake build'
    )
  end
end
