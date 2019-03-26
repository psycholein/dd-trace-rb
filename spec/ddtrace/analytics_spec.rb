require 'spec_helper'

require 'ddtrace/analytics'
require 'ddtrace/span'

RSpec.describe Datadog::Analytics do
  describe '.set_sample_rate' do
    subject(:set_sample_rate) { described_class.set_sample_rate(span, sample_rate) }
    let(:span) { instance_double(Datadog::Span) }
    let(:sample_rate) { 0.5 }

    before do
      allow(span).to receive(:set_metric) unless span.nil?
      set_sample_rate
    end

    context 'given span that is' do
      context 'nil' do
        let(:span) { nil }
        it { expect { set_sample_rate }.to_not raise_error }
      end
    end

    context 'given sample rate that is' do
      context 'nil' do
        let(:sample_rate) { nil }
        it { expect(span).to_not have_received(:set_metric) }
      end

      context 'a String' do
        let(:sample_rate) { '1.0' }
        it { expect(span).to_not have_received(:set_metric) }
      end

      context 'a Float' do
        let(:sample_rate) { 1.0 }

        it do
          expect(span).to have_received(:set_metric)
            .with(Datadog::Ext::Analytics::TAG_SAMPLE_RATE, sample_rate)
        end
      end
    end
  end
end

RSpec.describe Datadog::Analytics::Span do
  subject(:test_object) { test_class.new }

  describe '#set_tag' do
    subject(:set_tag) { test_object.set_tag(key, value) }

    before do
      allow(Datadog::Analytics).to receive(:set_sample_rate)
      set_tag
    end

    context 'when #set_tag is defined on the class' do
      let(:test_class) do
        Class.new do
          # Define this method here to prove it doesn't
          # override behavior in Datadog::Analytics::Span.
          def set_tag(key, value)
            [key, value]
          end

          # Include extensions at bottom (for Ruby 1.9 compatibility)
          include Datadog::Analytics::Span
        end
      end

      context 'and is given' do
        context 'some kind of tag' do
          let(:key) { 'my.tag' }
          let(:value) { 'my.value' }

          it 'calls the super #set_tag' do
            is_expected.to eq([key, value])
          end
        end

        context 'TAG_ENABLED with' do
          let(:key) { Datadog::Ext::Analytics::TAG_ENABLED }

          context 'true' do
            let(:value) { true }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, Datadog::Ext::Analytics::DEFAULT_SAMPLE_RATE)
            end
          end

          context 'false' do
            let(:value) { false }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, 0.0)
            end
          end

          context 'nil' do
            let(:value) { nil }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, 0.0)
            end
          end
        end

        context 'TAG_SAMPLE_RATE with' do
          let(:key) { Datadog::Ext::Analytics::TAG_SAMPLE_RATE }

          context 'a Float' do
            let(:value) { 0.5 }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, value)
            end
          end

          context 'a String' do
            let(:value) { '0.5' }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, value)
            end
          end

          context 'nil' do
            let(:value) { nil }

            it do
              expect(Datadog::Analytics).to have_received(:set_sample_rate)
                .with(test_object, value)
            end
          end
        end
      end
    end
  end
end