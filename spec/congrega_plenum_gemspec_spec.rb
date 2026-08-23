# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'congrega_plenum.gemspec' do
  let(:gem_specification) do
    Gem::Specification.load(File.expand_path('../congrega_plenum.gemspec', __dir__))
  end

  subject(:packaged_files) do
    gem_specification.files
  end

  it 'declara o copyleft de rede da AGPLv3 ou posterior' do
    expect(gem_specification.license).to eq('AGPL-3.0-or-later')
  end

  it 'inclui apenas os arquivos necessários em runtime e as assinaturas' do
    expect(packaged_files).to include(
      'CHANGELOG.md',
      'LICENSE',
      'README.md',
      'lib/congrega_plenum.rb',
      'sig/congrega_plenum.rbs'
    )
    expect(packaged_files).to all(match(%r{\A(?:CHANGELOG\.md|LICENSE|README\.md|lib/.+\.rb|sig/.+\.rbs)\z}))
  end

  it 'exclui documentação e cobertura geradas' do
    expect(packaged_files).not_to include(a_string_starting_with('doc/', 'coverage/'))
  end
end
