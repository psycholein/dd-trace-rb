require 'spec_helper'

require 'ddtrace'
require 'ddtrace/workers/trace_writer'

RSpec.describe Datadog::Workers::TraceWriter do
  describe '#write' do
    # TODO
  end

  describe '#perform' do
    # TODO
  end

  describe '#flush_traces' do
    # TODO
  end

  describe '#process_traces' do
    # TODO
  end

  describe '#inject_hostname!' do
    # TODO
  end

  describe '#flush_completed' do
    # TODO
  end

  describe described_class::FlushCompleted do
    describe '#name' do
      # TODO
    end

    describe '#publish' do
      # TODO
    end
  end
end

RSpec.describe Datadog::Workers::AsyncTraceWriter do
  subject(:writer) { described_class.new(options) }
  let(:options) { {} }

  describe '#perform' do
    subject(:perform) { writer.perform }
    after { writer.stop }

    it 'starts a worker thread' do
      is_expected.to be_a_kind_of(Thread)
      expect(writer).to have_attributes(
        run?: true,
        running?: true,
        unstarted?: false,
        forked?: false,
        fork_policy: :restart,
        result: nil
      )
    end
  end

  describe '#write' do
    # TODO
  end

  describe 'integration tests' do
    let(:options) { { transport: transport, fork_policy: fork_policy } }
    let(:transport) { Datadog::Transport::HTTP.default { |t| t.adapter :test, output } }
    let(:output) { [] }

    describe 'forking' do
      context 'when the process forks and a trace is written' do
        let(:traces) { get_test_traces(2) }

        before do
          allow(writer).to receive(:after_fork)
            .and_call_original
          allow(writer.transport).to receive(:send_traces)
            .and_call_original
        end

        after { writer.stop }

        context 'with :sync fork policy' do
          let(:fork_policy) { :sync }

          it 'does not drop any traces' do
            # Start writer in main process
            writer.perform

            expect_in_fork do
              traces.each do |trace|
                expect(writer.write(trace)).to be_a_kind_of(Datadog::Transport::HTTP::Response)
              end

              expect(writer).to have_received(:after_fork).once

              traces.each do |trace|
                expect(writer.transport).to have_received(:send_traces)
                  .with([trace])
              end

              expect(writer.buffer).to be_empty
            end
          end
        end

        context 'with :async fork policy' do
          let(:fork_policy) { :async }
          let(:flushed_traces) { [] }

          it 'does not drop any traces' do
            # Start writer in main process
            writer.perform

            expect_in_fork do
              # Queue up traces, wait for worker to process them.
              traces.each { |trace| writer.write(trace) }
              try_wait_until(attempts: 30) { !writer.work_pending? }

              # Verify state of the writer
              expect(writer).to have_received(:after_fork).once
              expect(writer.buffer).to be_empty
              expect(writer.error?).to be false

              expect(writer.transport).to have_received(:send_traces).at_most(2).times do |traces|
                flushed_traces.concat(traces)
              end

              expect(flushed_traces).to_not be_empty
              expect(flushed_traces).to have(2).items
              expect(flushed_traces).to include(*traces)
            end
          end
        end
      end
    end
  end
end
