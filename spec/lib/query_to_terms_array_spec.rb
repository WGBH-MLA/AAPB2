require 'rails_helper'

RSpec.describe QueryToTermsArray do
  describe '#terms_array' do
    let(:terms_array) { QueryToTermsArray.new(query).terms_array }

    context 'when query is empty' do
      let(:query) { '' }
      it 'returns an empty array' do
        expect(terms_array).to eq []
      end
    end

    context 'when query is not empty' do
      context 'and when query contains no quoted terms' do
        let(:query) { 'query without quoted terms' }
        it 'returns an array where each element is a single-element array ' \
           'containing each unquoted term from the query' do
          expect(terms_array).to eq [["QUERY"], ["WITHOUT"], ["QUOTED"], ["TERMS"]]
        end

        context 'and query contains punctuation' do
          let(:query) { %(`show_, ^me %+/- ice ? $@* cream}) }
          it 'returns an array containing each term without punctuation' do
            expect(terms_array).to eq [["SHOW"], ["ME"], ["ICE"], ["CREAM"]]
          end
        end
      end

      context 'and when query contains only a single quoted phrase' do
        let(:query) { '"quoted phrase"' }
        it 'returns an array where first and only element is an array of ' \
           'terms from the quoted phrase' do
          expect(terms_array).to eq [%w(QUOTED PHRASE)]
        end
      end

      context 'when query contains a mix of unquoted terms and quoted phrases' do
        let(:query) { 'unquoted stuff "quoted phrase"' }
        it 'returns an array where the first element is an array containing ' \
           'each term from the quoted phrase, and the remaining elements are ' \
           'single-element arrays containing the unquoted terms from the query' do
          expect(terms_array).to eq [%w(QUOTED PHRASE), ['UNQUOTED'], ['STUFF']]
        end
      end

      context 'when query contains multiple quoted phrases' do
        let(:query) { '"quoted phrase one" "another quoted phrase"' }
        it 'returns an array where each element is an array containing the ' \
           'terms from quoted phrases' do
          expect(terms_array).to eq [%w(QUOTED PHRASE ONE), %w(ANOTHER QUOTED PHRASE)]
        end
      end

      context 'when there are an odd number of quotation marks' do
        let(:query) { %("broken quotation" marks") }
        it 'ignores the last odd quotation mark' do
          expect(terms_array).to eq([%w(BROKEN QUOTATION), ["MARKS"]])
        end
      end

      context 'when query contains a quoted phrase with non-alphanumeric characters' do
        let(:query) { %("This` is_, a^quoted %+/- phrase ? $@*") }
        it 'returns an array where the elements are arrays of terms from the ' \
           'quoted phrase with all non-alphanumeric chars removed' do
          expect(terms_array).to eq [%w(THIS IS A QUOTED PHRASE)]
        end
      end

      context 'when query contains an unquoted stopword' do
        let(:query) { %(a search with no stopworda or stopwordb) }
        it 'uses stopwords.txt to remove words not used in actual search' do
          expect(terms_array).to eq([%w(SEARCH)])
        end
      end

      context 'when query contains a quoted stopword' do
        let(:query) { %(extremist is cheddar "president of the Eisenhower") }
        it 'preserves the stopword in the search' do
          expect(terms_array).to eq([%w(PRESIDENT OF THE EISENHOWER), ["EXTREMIST"], ["CHEDDAR"]])
        end
      end

      context 'when query contains numbers' do
        let(:query) { %(lost year "1958-59" 1960) }
        it 'leaves numbers in quoted and unquoted terms' do
          expect(terms_array).to eq([%w(1958 59), ["LOST"], ["YEAR"], ["1960"]])
        end
      end
    end
  end
end
