# frozen_string_literal: true

require 'bundler'
require 'open3'
require 'spec_helper'
require 'tmpdir'

# rubocop:disable Metrics/BlockLength
RSpec.describe 'Installed gem package' do
  let(:root) { File.expand_path('..', __dir__) }

  it 'carrega a versão sem depender da avaliação do gemspec pelo Bundler' do
    Dir.mktmpdir('congrega-plenum-package') do |temporary_directory|
      gem_file = File.join(temporary_directory, 'congrega_plenum.gem')
      install_directory = File.join(temporary_directory, 'installed')

      build_gem(gem_file)
      install_gem(gem_file, install_directory)

      stdout, stderr, status = run_installed_gem(install_directory)

      expect(status).to be_success, stderr
      expect(stdout).to eq("#{CongregaPlenum::VERSION}\n")
    end
  end

  def build_gem(gem_file)
    _stdout, stderr, status = Open3.capture3(
      'gem', 'build', 'congrega_plenum.gemspec', '--output', gem_file,
      chdir: root
    )

    expect(status).to be_success, stderr
  end

  def install_gem(gem_file, install_directory)
    _stdout, stderr, status = Bundler.with_unbundled_env do
      Open3.capture3(
        'gem', 'install', '--local', '--ignore-dependencies', '--no-document',
        '--install-dir', install_directory, gem_file
      )
    end

    expect(status).to be_success, stderr
  end

  def run_installed_gem(install_directory)
    environment = {
      'GEM_HOME' => install_directory,
      'GEM_PATH' => install_directory,
      'RUBYLIB' => nil,
      'RUBYOPT' => nil
    }
    script = 'require "congrega_plenum"; puts CongregaPlenum::VERSION'

    Bundler.with_unbundled_env do
      Open3.capture3(environment, RbConfig.ruby, '-e', script)
    end
  end
end
# rubocop:enable Metrics/BlockLength
