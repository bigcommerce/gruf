# Copyright 2017, Bigcommerce Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
# 3. Neither the name of BigCommerce Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require 'spec_helper'

describe Gruf::Service do
  let(:endpoint) { ThingService.new }
  let(:id) { 1 }
  let(:req) { ::Rpc::GetThingRequest.new(id: id) }
  let(:resp) { ::Rpc::GetThingResponse.new(id: id) }
  let(:call_signature) { :get_thing }
  let(:active_call) { double(:active_call, output_metadata: {}, metadata: {})}

  describe 'hooks' do
    subject { endpoint }

    describe '.before_call' do
      subject { endpoint.before_call(call_signature, req, active_call) }

      it 'should exist on the service' do
        expect(endpoint.respond_to?(:before_call)).to be_truthy
      end

      context 'with a hook registered' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeHook1)
        end

        it 'should call the before method on the hook' do
          expect(Gruf::Hooks::Registry.count).to eq 1
          expect(BeforeHook1).to receive(:verify).once, 'BeforeHook1 did not call .before'
          subject
        end
      end

      context 'with no hooks registered' do
        before do
          Gruf::Hooks::Registry.clear
        end

        it 'should just return normally' do
          expect(Gruf::Hooks::Registry.count).to eq 0
          expect(BeforeHook1).to_not receive(:verify), 'BeforeHook1 improperly called .before'
          subject
        end
      end

      context 'with multiple hooks registered' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:around_hook_1, AroundHook1)
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeHook1)
          Gruf::Hooks::Registry.add(:before_hook_2, BeforeHook2)
          Gruf::Hooks::Registry.add(:after_hook_1, AfterHook1)
          Gruf::Hooks::Registry.add(:before_hook_3, BeforeHook3)
          Gruf::Hooks::Registry.add(:after_hook_2, AfterHook2)
        end

        it 'should call the before method on all before hooks' do
          expect(Gruf::Hooks::Registry.count).to eq 6
          expect(AroundHook1).to_not receive(:verify), 'AroundHook1 was improperly called'
          expect(BeforeHook1).to receive(:verify).once, 'BeforeHook1 did not call .before'
          expect(BeforeHook2).to receive(:verify).once, 'BeforeHook2 did not call .before'
          expect(AfterHook1).to_not receive(:verify), 'AfterHook1 was improperly called'
          expect(BeforeHook3).to receive(:verify).once, 'BeforeHook3 did not call .before'
          expect(AfterHook2).to_not receive(:verify), 'AfterHook2 was improperly called'
          subject
        end
      end
    end

    describe '.after_call' do
      subject { endpoint.after_call(true, resp, call_signature, req, active_call) }

      it 'should exist on the service' do
        expect(endpoint.respond_to?(:after_call)).to be_truthy
      end

      context 'with a hook registered' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:after_hook_1, AfterHook1)
        end

        it 'should call the after method on the hook' do
          expect(Gruf::Hooks::Registry.count).to eq 1
          expect(AfterHook1).to receive(:verify).once, 'AfterHook1 did not call .after'
          subject
        end
      end

      context 'with multiple hooks registered' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:around_hook_1, AroundHook1)
          Gruf::Hooks::Registry.add(:after_hook_1, AfterHook1)
          Gruf::Hooks::Registry.add(:after_hook_2, AfterHook2)
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeHook1)
          Gruf::Hooks::Registry.add(:after_hook_3, AfterHook3)
          Gruf::Hooks::Registry.add(:before_hook_2, BeforeHook2)
        end

        it 'should call the before method on all after hooks' do
          expect(Gruf::Hooks::Registry.count).to eq 6
          expect(AroundHook1).to_not receive(:verify), 'AroundHook1 was improperly called'
          expect(AfterHook1).to receive(:verify).once, 'AfterHook1 did not call .before'
          expect(AfterHook2).to receive(:verify).once, 'AfterHook2 did not call .before'
          expect(BeforeHook1).to_not receive(:verify), 'BeforeHook1 was improperly called'
          expect(AfterHook3).to receive(:verify).once, 'AfterHook3 did not call .before'
          expect(BeforeHook2).to_not receive(:verify), 'BeforeHook2 was improperly called'
          subject
        end
      end
    end

    describe '.around_call' do
      subject { endpoint.around_call(call_signature, req, active_call) { Math.exp(2); true } }

      it 'should exist on the service' do
        expect(endpoint.respond_to?(:around_call)).to be_truthy
      end

      context 'with a hook registered' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:around_hook_1, AroundHook1)
        end

        it 'should call the around method on the hook' do
          expect(Gruf::Hooks::Registry.count).to eq 1
          expect(AroundHook1).to receive(:verify).once, 'AroundHook1 did not call .around'
          expect(Math).to receive(:exp).once
          subject
        end
      end

      context 'with no hooks registered' do
        before do
          Gruf::Hooks::Registry.clear
        end

        it 'should just call the proc' do
          expect(Math).to receive(:exp).once
          subject
        end
      end

      context 'with multiple hooks registered' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:around_hook_1, AroundHook1)
          Gruf::Hooks::Registry.add(:around_hook_2, AroundHook2)
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeHook1)
          Gruf::Hooks::Registry.add(:around_hook_3, AroundHook3)
          Gruf::Hooks::Registry.add(:after_hook_1, AfterHook1)
        end

        it 'should call the around method on each hook' do
          expect(Gruf::Hooks::Registry.count).to eq 5
          expect(AroundHook1).to receive(:verify).once, 'AroundHook1 did not call .around'
          expect(AroundHook2).to receive(:verify).once, 'AroundHook2 did not call .around'
          expect(BeforeHook1).to_not receive(:verify), 'BeforeHook1 improperly received call'
          expect(AroundHook3).to receive(:verify).once, 'AroundHook3 did not call .around'
          expect(AfterHook1).to_not receive(:verify), 'AfterHook1 improperly received call'
          expect(Math).to receive(:exp).once
          subject
        end
      end
    end
  end

  describe 'exceptions' do
    context 'failing with a NotFound error' do
      subject { endpoint.get_fail(req, active_call) }
      let(:error) { Gruf::Error.new(code: :not_found, app_code: :thing_not_found, message: "#{req.id} not found!") }

      it 'should raise a GRPC::NotFound error' do
        expect { subject }.to raise_error { |err|
          expect(err).to be_a(GRPC::NotFound)
          expect(err.code).to eq 5
          expect(err.message).to eq "5:#{id} not found!"
          expect(err.metadata).to eq(foo: 'bar', :'error-internal-bin' => error.serialize)
        }
      end
    end

    context 'on an uncaught exception' do
      subject { endpoint.get_uncaught_exception(req, active_call) }
      let(:error) { Gruf::Error.new(code: :internal, app_code: :unknown, message: 'epic fail') }

      it 'should raise a GRPC::Internal error' do
        expect { subject }.to raise_error { |err|
          expect(err).to be_a(GRPC::Internal)
          expect(err.code).to eq 13
          expect(err.message).to eq '13:epic fail'
          expect(err.metadata).to eq(:'error-internal-bin' => error.serialize)
        }
      end

      it 'should attach a backtrace if configured to do so' do
        Gruf.backtrace_on_error = true
        expect { subject }.to raise_error { |err|
          error = JSON.parse(err.metadata[:'error-internal-bin'])
          expect(error['debug_info']).to_not be_empty
          expect(error['debug_info']['stack_trace']).to_not be_empty
        }
      end
    end

    context 'on a success' do
      subject { endpoint.get_thing(req, active_call) }

      it 'should return normally' do
        expect(subject).to be_a(Rpc::GetThingResponse)
      end
    end
  end

  describe '.method_added' do
    it 'should add wrapper method for endpoint' do
      expect(endpoint.respond_to?(:get_thing_with_intercept)).to be_truthy
      expect(endpoint.respond_to?(:get_thing_without_intercept)).to be_truthy
    end

    it 'should not add wrapper method for non-endpoints' do
      expect(endpoint.respond_to?(:not_a_endpoint_with_intercept)).to_not be_truthy
      expect(endpoint.respond_to?(:not_a_endpoint_without_intercept)).to_not be_truthy
    end
  end

  describe '.authorize' do
    subject { endpoint.get_thing(req, active_call) }

    it 'should be called for every method call' do
      expect(endpoint).to receive(:authenticate).once
      expect(subject).to be_a(Rpc::GetThingResponse)
    end
  end

  describe 'functional test' do
    let(:client) { TestClient.new }
    let(:id) { 1 }
    subject { client.get_thing(id: id) }

    it 'should return the thing' do
      expect(subject).to be_a(Rpc::GetThingResponse)
      expect(subject.id).to eq id
    end
  end
end
