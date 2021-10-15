require 'sesame_street_alert'

RSpec.describe SesameStreetAlert do
  describe '#guids' do
    it 'is not empty' do
      expect(SesameStreetAlert.guids).to_not be_empty
    end
  end


  describe '#show?' do
    let(:sesame_st_guid) { SesameStreetAlert.guids.sample }
    let(:non_sesame_st_guid) { 'cpb-aacip-123abc' }

    context 'when the its a sesame street guid' do
      it 'returns true' do
        expect(SesameStreetAlert.show?(sesame_st_guid)).to be true
      end
    end

    context 'when it is not a sesame street guid' do
      it 'returns false' do
        expect(SesameStreetAlert.show?(non_sesame_st_guid)).to be false
      end
    end
  end
end
