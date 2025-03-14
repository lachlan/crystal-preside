require "./service"

module Preside
  # Abstract supervisor which can start/stop/restart a list of services
  abstract class Supervisor < Service
    # List of services managed by this supervisor
    @services = Array(Service).new

    # Starts the supervisor and its managed services
    def start : Nil
      if stopped?
        @status_mutex.synchronize do
          if stopped?
            super
            @services.each &.start
          end
        end
      end
    end

    # Stops the supervisor and its managed services
    def stop : Nil
      if started? || starting?
        @status_mutex.synchronize do
          if started? || starting?
            @services.reverse.each &.stop
            super
          end
        end
      end
    end

    # Terminates the supervisor and its managed services
    def terminate : Nil
      unless terminated?
        @status_mutex.synchronize do
          unless terminated?
            @services.reverse.each &.terminate
            super
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
              dependents << Health.new(service.name, results)
              Log.error(exception: ex) { "HEALTH-CHECK #{service.name} failed" }
            end
          end
          supervisor_health = Health.new(name, nil, dependents) unless dependents.empty?
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
