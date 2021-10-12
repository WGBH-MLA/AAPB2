require 'spec_helper'
require_relative '../../scripts/lib/deleter'

describe Deleter do

  context 'with an Array with invalid ID' do
    describe '.new' do
      it 'fails on an invalid ID' do
        expect{ Deleter.new(["123"]) }.to raise_error(SystemExit)
      end
    end
  end

  context 'with an Array of valid IDs' do
    describe '.new' do
      it 'passes ID validation' do
        expect{ Deleter.new(["cpb-aacip-123456", "cpb-aacip-78910"]) }.not_to raise_error
      end
    end

    describe '.delete' do
      let(:ids) { [ "cpb-aacip-123456" ] }
      let(:deleter) { Deleter.new(ids) }
      let(:fake_ingester) { instance_double(PBCoreIngester) }

      before do
        allow(deleter).to receive(:ingester).and_return(fake_ingester)
        allow(fake_ingester).to receive(:delete_records).with(ids)
        deleter.delete
      end

      it 'passes the Array of IDs to PBCoreIngester to delete' do
        expect(fake_ingester).to have_received(:delete_records).with(ids)
      end
    end
  end

  context "with something other than an Array" do
    describe '.new' do
      it 'raises an error' do
        expect{ Deleter.new("cpb-aacip-123456") }.to raise_error(RuntimeError, "Invalid arguments for deleting AAPB records. Must be an Array of IDs.")
      end
    end
  end
end
