require 'rails_helper'

RSpec.describe QueryToTermsArray do
  describe '#terms_array' do

    let(:terms_array) { QueryToTermsArray.new(query).terms_array }

    context 'when query is empty' do
      let(:query) { '' }
      it 'raises an error' do
        expect { terms_array }.to raise_error ArgumentError
      end
    end

    context 'when query is not empty' do
      context 'and when query contains no quoted terms' do
        let(:query) { 'a query with no quoted terms' }
        it 'returns an array where each element is a single-element array ' \
           'containing each unquoted term from the query' do
          expect(terms_array).to eq [["QUERY"], ["QUOTED"], ["TERMS"]]
        end

        context 'and query contains punctuation' do
          let(:query) { %(`show_, ^me %+/- the ? $@*) }
          it 'returns an array containing each term without punctuation' do
            expect(terms_array).to eq [["SHOW"], ["ME"]]
          end
        end
      end

      context 'and when query contains only a single quoted phrase' do
        let(:query) { '"quoted phrase"'}
        it 'returns an array where first and only element is an array of ' \
           'terms from the quoted phrase' do
          expect(terms_array).to eq [["QUOTED", "PHRASE"]]
        end
      end

      context 'when query contains a mix of unquoted terms and quoted phrases' do
        let(:query) { 'unquoted stuff "quoted phrase"' }
        it 'returns an array where the first element is an array containing ' \
           'each term from the quoted phrase, and the remaining elements are ' \
           'single-element arrays containing the unquoted terms from the query' do
          expect(terms_array).to eq [["QUOTED", "PHRASE"], ['UNQUOTED'], ['STUFF']]
        end
      end

      context 'when query contains multiple quoted phrases' do
        let(:query) { '"quoted phrase one" "another quoted phrase"' }
        it 'returns an array where each element is an array containing the ' \
           'terms from quoted phrases' do
          expect(terms_array).to eq [["QUOTED", "PHRASE", "ONE"], ["ANOTHER", "QUOTED", "PHRASE"]]
        end
      end

      context 'when query contains a quoted phrase with non-alphanumeric characters' do
        let(:query) { %("This` is_, a^quoted %+/- phrase ? $@*") }
        it 'returns an array where the elements are arrays of terms from the ' \
           'quoted phrase with all non-alphanumeric chars removed' do
          expect(terms_array).to eq [["THIS", "IS", "A", "QUOTED", "PHRASE"]]
        end
      end
    end
  end
end
