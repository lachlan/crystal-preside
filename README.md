# Preside

Crystal language shard which provides simple abstract classes for services
that can start/stop/restart, and supervisors which can start/stop/restart
a list of managed services.

```
┌──────────┐    ┌───────┐    ┌────────┐    ┌───────┐
│TERMINATED│◄───┤STOPPED├───►│STARTING├───►│STARTED│
└──────────┘    └───────┘    └───┬────┘    └───────┘
                    ▲            │             │
                    │            ▼             │
                    │        ┌────────┐        │
                    └────────┤STOPPING│◄───────┘
                             └────────┘
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     preside:
       github: lachlan/crystal-preside
   ```

2. Run `shards install`

## Usage

```crystal
require "preside"

class Service < Preside::Service
  # implement specific steps to start the service
  protected def startup : Nil
    # ...
  end

  # implement run loop logic
  protected def run : Nil
    while started?
      # do something
      snooze
    end
  end

  # implement specific steps to stop the service
  protected def shutdown : Nil
    # ...
  end
end

class Supervisor < Preside::Supervisor
  def init
    @services << Service.new
  end
end

supervisor = Supervisor.new
supervisor.start # starts self and all managed services
supervisor.await # waits for self and all managed services to terminate
```

## Contributing

1. Fork it (<https://github.com/lachlan/crystal-preside/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Lachlan Dowding](https://github.com/lachlan) - creator and maintainer
