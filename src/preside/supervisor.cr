require "./service"

module Preside
  # Abstract supervisor which can start/stop/restart a list of services
  abstract class Supervisor < Service
    # List of services managed by this supervisor
    @services = Array(Service).new

    # Starts the supervisor and its managed services
    def start : Nil
      if stopped?
        loop do
          begin
            if stopped?
              super
              @services.each do |service|
                begin
                  service.start
                rescue ex
                  Log.error(exception: ex) { "STARTING #{service.name} FAILED" }
                  raise ex
                end
              end
            end
          rescue ex
            Log.error(exception: ex) { "STARTING #{name} FAILED, retrying in #{RETRY_INTERVAL}" }
            stop # clean up if start failed

            # take a bunch of little naps until RETRY_INTERVAL has passed then try again
            end_time = Time.instant + RETRY_INTERVAL
            while !started? && !starting? && Time.instant < end_time
              sleep DEFAULT_SNOOZE_INTERVAL
            end
          else
            break
          end
        end
      end
    end

    # Stops the supervisor and its managed services
    def stop : Nil
      if started? || starting?
        loop do
          begin
            if started? || starting?
              @services.reverse.each do |service|
                begin
                  service.stop
                rescue ex
                  Log.error(exception: ex) { "STOPPING #{service.name} FAILED" }
                  raise ex
                end
              end
              super
            end
          rescue ex
            Log.error(exception: ex) { "STOPPING #{name} FAILED, retrying in #{RETRY_INTERVAL}" }

            # take a bunch of little naps until RETRY_INTERVAL has passed then try again
            end_time = Time.instant + RETRY_INTERVAL
            while !stopped? && Time.instant < end_time
              sleep DEFAULT_SNOOZE_INTERVAL
            end
          else
            break
          end
        end
      end
    end

    # Terminates the supervisor and its managed services
    def terminate : Nil
      unless terminated?
        loop do
          begin
            unless terminated?
              @services.reverse.each do |service|
                begin
                  service.terminate
                rescue ex
                  Log.error(exception: ex) { "TERMINATE #{service.name} FAILED" }
                end
              end
              super
            end
          rescue ex
            Log.error(exception: ex) { "TERMINATE #{name} FAILED, retrying in #{RETRY_INTERVAL}" }

            # take a bunch of little naps until RETRY_INTERVAL has passed then try again
            end_time = Time.instant + RETRY_INTERVAL
            while !terminated? && Time.instant < end_time
              sleep DEFAULT_SNOOZE_INTERVAL
            end
          else
            break
          end
        end
      end
    end

    # Waits for the supervisor to terminate
    def await : Nil
      @services.reverse.each &.await
      super
    end

    # Returns the current health of the supervisor and its managed services
    def health : Health?
      @status_mutex.synchronize do
        supervisor_health : Health? = nil
        supervisor_healthy = true
        dependents : Array(Health)? = nil
        unless @services.empty?
          dependents = Array(Health).new
          @services.each do |service|
            begin
              if health = service.health
                dependents << health
              end
            rescue ex
              results = Array(Health::Result).new
              results << Health::Result.new("Exception raised by health check: #{ex}", false)
              dependents << Health.new(service.name, service.description, results)
              Log.error(exception: ex) { "HEALTH-CHECK #{service.name} failed" }
            end
          end
          supervisor_health = Health.new(name, description, nil, dependents) unless dependents.empty?
        end
        return supervisor_health
      end
    end

    # Returns the list of services managed by this supervisor
    def services : Array(Service)
      @services.dup
    end
  end
end
