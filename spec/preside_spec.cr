require "./spec_helper"

describe Preside::Service do
  it "starts" do
    service = TestService.new

    service.started?.should eq(false)
    service.was_started?.should eq(false)
    service.start
    service.was_started?.should eq(true)
    service.started?.should eq(true)
  end

  it "stops" do
    service = TestService.new
    service.start

    service.was_stopped?.should eq(false)
    service.stop
    service.was_stopped?.should eq(true)
  end
end

describe Preside::Supervisor do
  it "starts" do
    supervisor = TestSupervisor.new

    supervisor.was_started?.should eq(false)
    supervisor.services.each do |service|
      service.as(TestService).was_started?.should eq(false)
    end

    supervisor.start

    supervisor.was_started?.should eq(true)
    supervisor.services.each do |service|
      service.as(TestService).was_started?.should eq(true)
    end
  end

  it "stops" do
    supervisor = TestSupervisor.new
    supervisor.start

    supervisor.was_stopped?.should eq(false)
    supervisor.services.each do |service|
      service.as(TestService).was_stopped?.should eq(false)
    end

    supervisor.stop

    supervisor.was_stopped?.should eq(true)
    supervisor.services.each do |service|
      service.as(TestService).was_stopped?.should eq(true)
    end
  end

  it "checks health" do
    supervisor = TestSupervisor.new
    supervisor.start

    if health = supervisor.health
      health.healthy?.should eq(false)
    end
  end

  it "filters unhealthy" do
    supervisor = TestSupervisor.new
    supervisor.start

    if (health = supervisor.health) && (unhealthy = health.unhealthy_only)
      unhealthy.healthy?.should eq(false)
    end
  end
end
