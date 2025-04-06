require "json"

module Preside
  module Health
    # Report on the health or otherwise of a component
    class Health
      include JSON::Serializable

      # Individual health check result for a component
      class Result
        include JSON::Serializable

        # Describes the specific health check
        getter description : String
        # Whether the specific health check passed (true) or failed (false)
        getter? healthy : Bool

        def initialize(@description : String, @healthy : Bool)
        end
      end

      # The name of the component whose health was checked
      getter component : String
      # The time the health report was generated
      getter datetime : Time = Time.local
      # Whether the component is healthy (true) or unhealthy (false)
      getter? healthy : Bool
      # The list of health checks undertaken to determine component health
      getter results : Array(Result)?
      # The list of dependent components whose health was checked to determine the health of this component
      getter dependents : Array(Health)?

      def initialize(@component : String, @results : Array(Result)? = nil, @dependents : Array(Health)? = nil)
        @healthy = calculate_health
      end

      # Is this component healthy?
      protected def calculate_health : Bool
        healthy = true
        if healthy && (results = @results)
          results.each do |result|
            healthy = healthy && result.healthy?
          end
        end
        if healthy && (dependents = @dependents)
          dependents.each do |dependent|
            healthy = healthy && dependent.healthy?
          end
        end
        healthy
      end

      # Is this component unhealthy?
      def unhealthy? : Bool
        !healthy?
      end

      # Filters the health results to only include unhealthy checks or dependents
      def unhealthy_only : Health?
        health : Health? = nil
        filtered_results : Array(Result)? = nil
        filtered_dependents : Array(Health)? = nil
        if unhealthy?
          if results = @results
            filtered_results = results.reject { |r| r.healthy? }
            filtered_results = nil if filtered_results.empty?
          end
          if dependents = @dependents
            filtered_dependents = dependents.reject { |d| d.healthy? }.map { |d| d.unhealthy_only }.compact
            filtered_dependents = nil if filtered_dependents.empty?
          end
          health = Health.new(@component, filtered_results, filtered_dependents)
        end
        health
      end
    end

    # Returns the current health of the service, or nil if not implemented
    def health : Health?
      return nil
    end
  end
end
