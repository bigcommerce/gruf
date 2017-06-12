module Gruf
  module Helpers
    ##
    # Build a gRPC operation stub for testing
    #
    def build_operation(options = {})
      double(:operation, {
        execute: true,
        metadata: {},
        trailing_metadata: {},
        deadline: Time.now.to_i + 3600,
        cancelled?: false,
        execution_time: rand(1_000..10_000)
       }.merge(options))
    end
  end
end
