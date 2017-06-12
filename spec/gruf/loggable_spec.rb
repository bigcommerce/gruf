require 'spec_helper'

class TestLoggable
  include Gruf::Loggable
end

describe Gruf::Loggable do
  let(:cls) { TestLoggable.new }
  subject { cls.logger }

  it 'should add a logger method when included' do
    expect(subject).to eq Gruf.logger
  end
end
