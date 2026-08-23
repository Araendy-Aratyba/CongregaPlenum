# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'congrega_plenum.gemspec' do
  subject(:packaged_files) do
    Gem::Specification.load(File.expand_path('../congrega_plenum.gemspec', __dir__)).files
  end

  it 'inclui apenas os arquivos necessários em runtime e as assinaturas' do
    expect(packaged_files).to include('LICENSE', 'README.md', 'lib/congrega_plenum.rb', 'sig/congrega_plenum.rbs')
    expect(packaged_files).to all(match(%r{\A(?:LICENSE|README\.md|lib/.+\.rb|sig/.+\.rbs)\z}))
  end

  it 'exclui documentação e cobertura geradas' do
    expect(packaged_files).not_to include(a_string_starting_with('doc/', 'coverage/'))
  end
end
