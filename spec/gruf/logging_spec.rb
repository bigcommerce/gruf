require 'spec_helper'

class TestLogging
  include Gruf::Logger
end
class TestGrpcLogging
  include Gruf::GrpcLogger
end

describe Gruf::Logger do
  let(:cls) { TestLogging.new }
  subject { cls.logger }

  it 'should add a logger method when included' do
    expect(subject).to eq Gruf.logger
  end
end

describe Gruf::GrpcLogger do
  let(:cls) { TestGrpcLogging.new }
  subject { cls.logger }

  it 'should add a logger method when included' do
    expect(subject).to eq Gruf.grpc_logger
  end
end
