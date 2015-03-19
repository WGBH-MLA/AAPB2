require_relative '../../app/models/featured'

describe Featured do
  it 'works' do
    expect { Featured.from_gallery('home') }.not_to raise_error
  end
end
