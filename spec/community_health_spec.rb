# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe 'Community health files' do
  let(:root) { File.expand_path('..', __dir__) }

  it 'mantém os documentos comunitários essenciais' do
    files = %w[CHANGELOG.md CODE_OF_CONDUCT.md CONTRIBUTING.md LICENSE README.md SECURITY.md]

    expect(files).to all(satisfy { |file| File.file?(File.join(root, file)) })
  end

  it 'mantém formulários válidos para bugs e melhorias' do
    template_root = File.join(root, '.github/ISSUE_TEMPLATE')

    %w[bug_report.yml feature_request.yml].each do |filename|
      form = YAML.safe_load_file(File.join(template_root, filename), aliases: true)

      expect(form).to include('name' => be_a(String), 'description' => be_a(String), 'body' => be_an(Array))
    end
  end

  it 'aponta README e política de segurança para canais públicos válidos' do
    readme = File.read(File.join(root, 'README.md'))
    security = File.read(File.join(root, 'SECURITY.md'))

    expect(readme).to include('https://diafania-claritas.github.io/CongregaPlenum/', 'CONTRIBUTING.md')
    expect(readme).to include('assets/branding/diafania-claritas-logo.svg',
                              'assets/branding/diafania-claritas-logo-inverse.svg')
    expect(security).to include('https://github.com/Diafania-Claritas/CongregaPlenum/security/advisories/new')
  end
end
