require "spec"
require "../src/preside"

class TestService < Preside::Service
  getter? was_started = false
  getter? was_stopped = false

  def initialize(@healthy : Bool = true)
  end

  def health : Health
    results = Array(Health::Result).new
    results << Health::Result.new("Testing", @healthy)
    return Health.new(self.to_s, nil, results)
  end

  protected def startup : Nil
    @was_started = true
  end

  protected def shutdown : Nil
    @was_stopped = true
  end

  protected def run : Nil
    while started?
      snooze 5.seconds
    end
  end
end

class TestSupervisor < Preside::Supervisor
  getter? was_started = false
  getter? was_stopped = false

  def initialize
    @services << TestService.new(true)
    @services << TestService.new(false)
  end

  protected def startup : Nil
    @was_started = true
  end

  protected def shutdown : Nil
    @was_stopped = true
  end
end

class StartFailureService < Preside::Service
  getter startup_count : Int32 = 0

  protected def startup : Nil
    @startup_count += 1

    puts "#{Time.utc} called startup #{@startup_count} times"

    raise "oh no"
  end
end
