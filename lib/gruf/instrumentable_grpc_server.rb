# frozen_string_literal: true

module Gruf
  ##
  # A subclass of GRPC::RpcServer that can be used for enhanced monitoring
  # of thread pool. Note that since we are reaching into the internals of
  # GRPC::RpcServer, we need to watch the evolution of that class.
  #
  class InstrumentableGrpcServer < GRPC::RpcServer
    ##
    # Add an event_listener_proc that, if supplied, will be called
    # when interesting events happen in the server.
    #
    def initialize(pool_size: DEFAULT_POOL_SIZE,
                   max_waiting_requests: DEFAULT_MAX_WAITING_REQUESTS,
                   poll_period: DEFAULT_POLL_PERIOD,
                   pool_keep_alive: Pool::DEFAULT_KEEP_ALIVE,
                   connect_md_proc: nil,
                   server_args: {},
                   interceptors: [],
                   event_listener_proc: nil)
      # Call the base class initializer
      super(
        pool_size: pool_size,
        max_waiting_requests: max_waiting_requests,
        poll_period: poll_period,
        pool_keep_alive: pool_keep_alive,
        connect_md_proc: connect_md_proc,
        server_args: server_args,
        interceptors: interceptors
      )

      # Save event listener for later
      @event_listener_proc = event_listener_proc
    end

    ##
    # Notify the event listener of something interesting
    #
    def notify(event)
      return if @event_listener_proc.nil? || !@event_listener_proc.respond_to?(:call)

      @event_listener_proc.call(event)
    end

    ##
    # Hook into the thread pool availability check for monitoring
    #
    def available?(an_rpc)
      super.tap do |obj|
        notify(:thread_pool_exhausted) unless obj
      end
    end

    ##
    # Hook into the method implementation check for monitoring
    #
    def implemented?(an_rpc)
      super.tap do |obj|
        notify(:unimplemented) unless obj
      end
    end
  end
end
