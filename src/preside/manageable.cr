require "json"
require "log"
require "wait_group"
require "./status"

module Preside
  # Superclass for objects which can start/stop/restart/terminate
  abstract class Manageable
    # Lock used to synchronize start/stop/restart/terminate actions
    @status_mutex = Mutex.new(Mutex::Protection::Reentrant)
    # The status of the service
    @status : Atomic(Status) = Atomic.new(Status::STOPPED)
    # The wait group for spawning and waiting on tasks
    @tasks : WaitGroup = WaitGroup.new

    # Name used when logging, can be overridden
    def name : String
      self.to_s
    end

    # Description explaining the function of the object
    def description : String?
      nil
    end

    # Whether this service is terminated
    def terminated? : Bool
      @status.get == Status::TERMINATED
    end

    # Whether this service is stopped
    def stopped? : Bool
      @status.get == Status::STOPPED
    end

    # Whether this service is stopping
    def stopping? : Bool
      @status.get == Status::STOPPING
    end

    # Whether this service is stopping
    def starting? : Bool
      @status.get == Status::STARTING
    end

    # Whether this service is started
    def started? : Bool
      @status.get == Status::STARTED
    end

    # Starts this object
    def start : Nil
      if stopped?
        @status_mutex.synchronize do
          if stopped?
            @status.set Status::STARTING
            Log.debug { "STARTING #{name}" }

            startup

            @status.set Status::STARTED
            Log.debug { "STARTED #{name}" }

            if self.responds_to?(:run)
              @tasks.spawn do
                begin
                  run
                ensure
                  stop
                end
              end
            end
          end
        end
      end
    end

    # Stops this object
    def stop : Nil
      if started? || starting?
        @status_mutex.synchronize do
          if started? || starting?
            @status.set Status::STOPPING
            Log.debug { "STOPPING #{name}" }

            @tasks.wait # tasks should exit as status is no longer started
            shutdown

            @status.set Status::STOPPED
            Log.debug { "STOPPED #{name}" }
          end
        end
      end
    end

    # Terminates by stopping and disallowing starting again
    def terminate : Nil
      unless terminated?
        @status_mutex.synchronize do
          unless terminated?
            stop
            @status.set Status::TERMINATED
            Log.debug { "TERMINATED #{name}" }
          end
        end
      end
    end

    # Restarts by stopping then and starting again
    def restart : Nil
      if started?
        @status_mutex.synchronize do
          if started?
            stop
            start
          end
        end
      end
    end

    # Waits for termination for the given timeout
    def await(timeout : Time::Span) : Nil
      channel = Channel(Nil).new
      spawn do
        await
      ensure
        channel.send nil
      end

      select
      when channel.receive
        # await completed within timeout period
      when timeout(timeout)
        # await timed out
      end
    end

    # Waits for termination
    def await : Nil
      while !terminated?
        sleep 1.second
      end
    end

    # Called synchronously by start to perform tasks for starting the service
    abstract def startup : Nil

    # Called synchronously by stop to perform tasks for stopping the service
    abstract def shutdown : Nil
  end
end
