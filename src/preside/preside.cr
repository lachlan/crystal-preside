require "log"

module Preside
  Log            = ::Log.for("PRESIDE")
  RETRY_INTERVAL = 20.seconds
end

require "./service"
require "./supervisor"
