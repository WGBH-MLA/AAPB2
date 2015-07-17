require_relative '../../app/models/featured'

describe Featured do
  it 'does not raise error' do
    expect { Featured.from_gallery('home') }.not_to raise_error
  end
end
