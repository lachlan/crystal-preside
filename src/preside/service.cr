require "wait_group"
require "./health"
require "./manageable"

module Preside
  # Abstract service which can be started/stopped/restarted
  abstract class Service < Manageable
    include Health

    # The duration of naps taken while snooze loops
    DEFAULT_SNOOZE_INTERVAL = 100.milliseconds

    # Sleeps for the given interval while status remains STARTED with a bunch
    # of small sleeps to allow detection of status changes
    protected def snooze(interval : Time::Span = DEFAULT_SNOOZE_INTERVAL) : Nil
      raise "interval must not be negative: #{interval}" if interval.negative?

      if started?
        retry_interval = interval < DEFAULT_SNOOZE_INTERVAL ? interval : DEFAULT_SNOOZE_INTERVAL
        end_time = Time.instant + interval

        while started? && Time.instant < end_time
          sleep retry_interval
        end
      end
    end

    # Performs startup tasks for this service
    protected def startup : Nil
      # do nothing, to be overridden
    end

    # Called asynchronously by start after startup completes successfully.
    # When execution completes the object is stopped
    protected def run : Nil
      # example run loop
      while started?
        # run loop logic goes here
        snooze 1.second
      end
    end

    # Performs shutdown tasks for this service
    protected def shutdown : Nil
      # do nothing, to be overridden
    end
  end
end
