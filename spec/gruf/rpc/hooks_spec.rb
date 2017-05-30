require 'spec_helper'

describe Gruf::Service do
  let(:endpoint) { ThingService.new }
  let(:id) { 1 }
  let(:req) { ::Rpc::GetThingRequest.new(id: id) }
  let(:resp) { ::Rpc::GetThingResponse.new(id: id) }
  let(:call_signature) { :get_thing }
  let(:active_call) { double(:active_call, output_metadata: {}, metadata: {})}

  subject { endpoint }

  describe '.before_call' do
    subject { endpoint.before_call(call_signature, req, active_call) }

    it 'should exist on the service' do
      expect(endpoint.respond_to?(:before_call)).to be_truthy
    end

    context 'with one hook registered' do
      context 'that is a successful hook' do
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

      context 'that is calls an exception' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeExceptionHook1)
        end

        it 'should call the before method on the hook and raise the exception' do
          expect(Gruf::Hooks::Registry.count).to eq 1
          expect(BeforeExceptionHook1).to receive(:verify).once, 'BeforeExceptionHook1 did not call .before'
          expect { subject }.to raise_error(StandardError)
        end
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
      context 'and they all are successful' do
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

      context 'and the first before hook raises an exception' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeExceptionHook1)
          Gruf::Hooks::Registry.add(:before_hook_2, BeforeHook2)
        end

        it 'should raise an exception and not call the second hook' do
          expect(Gruf::Hooks::Registry.count).to eq 2
          expect(BeforeExceptionHook1).to receive(:verify).once, 'BeforeExceptionHook1 did not call .before'
          expect(BeforeHook2).to_not receive(:verify), 'BeforeHook2 should not have received .before'
          expect { subject }.to raise_error(StandardError)
        end
      end

      context 'and the second before hook raises an exception' do
        before do
          Gruf::Hooks::Registry.clear
          Gruf::Hooks::Registry.add(:before_hook_1, BeforeHook1)
          Gruf::Hooks::Registry.add(:before_hook_2, BeforeExceptionHook1)
        end

        it 'should raise an exception but still call the first hook' do
          expect(Gruf::Hooks::Registry.count).to eq 2
          expect(BeforeHook1).to receive(:verify).once, 'BeforeHook1 did not have call .before'
          expect(BeforeExceptionHook1).to receive(:verify).once, 'BeforeExceptionHook1 did not call .before'
          expect { subject }.to raise_error(StandardError)
        end
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
        subject
      end

      it 'should only call the actual request once' do
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
        subject
      end

      it 'should only call the actual request once' do
        expect(Math).to receive(:exp).once
        subject
      end
    end
  end

  describe '.outer_around_call' do
    subject { endpoint.outer_around_call(call_signature, req, active_call) { Math.exp(2); true } }

    it 'should exist on the service' do
      expect(endpoint.respond_to?(:outer_around_call)).to be_truthy
    end

    context 'with a hook registered' do
      before do
        Gruf::Hooks::Registry.clear
        Gruf::Hooks::Registry.add(:outer_around_hook_1, OuterAroundHook1)
      end

      it 'should call the around method on the hook' do
        expect(Gruf::Hooks::Registry.count).to eq 1
        expect(OuterAroundHook1).to receive(:verify).once, 'OuterAroundHook1 did not call .around'
        subject
      end

      it 'should only call the actual request once' do
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
        Gruf::Hooks::Registry.add(:outer_around_hook_1, OuterAroundHook1)
        Gruf::Hooks::Registry.add(:outer_around_hook_2, OuterAroundHook2)
        Gruf::Hooks::Registry.add(:before_hook_1, BeforeHook1)
        Gruf::Hooks::Registry.add(:outer_around_hook_3, OuterAroundHook3)
        Gruf::Hooks::Registry.add(:after_hook_1, AfterHook1)
      end

      it 'should call the outer_around method on each appropriate hook' do
        expect(Gruf::Hooks::Registry.count).to eq 5
        expect(OuterAroundHook1).to receive(:verify).once, 'OuterAroundHook1 did not call .around'
        expect(OuterAroundHook2).to receive(:verify).once, 'OuterAroundHook2 did not call .around'
        expect(BeforeHook1).to_not receive(:verify), 'BeforeHook1 improperly received call'
        expect(OuterAroundHook3).to receive(:verify).once, 'OuterAroundHook3 did not call .around'
        expect(AfterHook1).to_not receive(:verify), 'AfterHook1 improperly received call'
        subject
      end

      it 'should only call the actual request once' do
        expect(Math).to receive(:exp).once
        subject
      end
    end
  end
end
