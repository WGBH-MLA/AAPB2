require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe '#convert_seconds_to_hms' do
    let(:time) { seconds_to_hms(seconds) }

    context 'when input is nil' do
      let(:seconds) { nil }
      it 'returns 00:00:00' do
        expect(time).to eq '00:00:00'
      end
    end

    context 'when input is empty' do
      let(:seconds) { '' }
      it 'returns 00:00:00' do
        expect(time).to eq '00:00:00'
      end
    end

    context 'when input is not empty' do
      context 'and when input contains non-digits' do
        let(:seconds) { '3 hours 2 minutes and 1 second' }
        it 'returns nil' do
          expect(time).to eq nil
        end
      end

      context 'when input is 0' do
        let(:seconds) { 0 }
        it 'returns 00:00:00' do
          expect(time).to eq '00:00:00'
        end
      end

      context 'when input is an integer' do
        let(:seconds) { 3 }
        it 'parses the number as the number of seconds: 00:00:03' do
          expect(time).to eq '00:00:03'
        end
      end
  
      context 'when input is a string' do
        let(:seconds) { '3661.1' }
        it 'returns 01:01:01' do
          expect(time).to eq '01:01:01'
        end
      end

      context 'when input is a float' do
        let(:seconds) { 45296.38 }
        it 'returns 12:34:56' do
          expect(time).to eq '12:34:56'
        end
      end
    end
  end
end
