# Provides abstract classes for services which can start/stop/restart, and
# for supervisors which can start/stop/restart a list of managed services.
module Preside
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}
end

require "./preside/preside"
