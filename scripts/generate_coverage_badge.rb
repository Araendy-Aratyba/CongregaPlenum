# frozen_string_literal: true

require 'fileutils'
require 'json'

source = ARGV.fetch(0, 'coverage/.last_run.json')
destination = ARGV.fetch(1, 'doc/coverage.json')
result = JSON.parse(File.read(source))
line_coverage = result.dig('result', 'line')

abort "Cobertura de linhas ausente em #{source}" unless line_coverage.is_a?(Numeric)

color = case line_coverage
        when 90.. then 'brightgreen'
        when 80...90 then 'green'
        when 70...80 then 'yellowgreen'
        when 60...70 then 'yellow'
        else 'red'
        end

badge = {
  schemaVersion: 1,
  label: 'coverage',
  message: format('%.2f%%', line_coverage),
  color: color
}

FileUtils.mkdir_p(File.dirname(destination))
File.write(destination, JSON.generate(badge))
