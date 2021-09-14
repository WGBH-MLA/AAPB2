require 'spec_helper'
require 'aapb'

describe AAPB do

  describe '#valid_id' do
    it 'returns true for an ids that begin with cpb-aacip(-|_|/)' do
      %w(cpb-aacip-111-21ghx7d6 cpb-aacip-a1bcd4fc0e1 cpb-aacip_111-21ghx7d6 cpb-aacip/111-21ghx7d6).each do |id|
        expect(AAPB.valid_id?(id)).to eq(true)
      end
    end

    it 'returns false for other ids' do
      [ 1,  "1", "not-an-id" ].each do |id|
        expect(AAPB.valid_id?(id)).to eq(false)
      end
    end
  end
end
