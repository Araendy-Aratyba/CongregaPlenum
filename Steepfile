# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature 'sig'
  check 'lib/congrega_plenum.rb'
  check 'lib/adapters/**/*.rb'
  check 'lib/client.rb'
  check 'lib/modules/**/*.rb'

  library 'logger'
  library 'json'
  library 'net-http'
  library 'socket'
  library 'singleton'
  library 'uri'
end
