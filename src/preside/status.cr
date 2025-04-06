module Preside
  enum Status
    TERMINATED # stopped and disallowed to start
    STOPPED    # stopped and allowed to start
    STOPPING   # stopping
    STARTING   # starting
    STARTED    # started and allowed to stop or terminate
  end
end
