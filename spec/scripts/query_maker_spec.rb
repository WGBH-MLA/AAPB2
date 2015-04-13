require_relative '../../scripts/lib/query_maker'

describe QueryMaker do
  it 'warns about unrecognized params' do
    expect { QueryMaker.translate('random=param') }.to raise_exception RuntimeError
  end

  it 'handles text search' do
    expect(QueryMaker.translate('q=art')).to eq 'text:"art"'
  end

  it 'handles mult facet search' do
    query = 'f[genres][]=Interview&f[genres][]=Performance'
    expect(QueryMaker.translate(query)).to eq 'genres:"Interview" genres:"Performance"'
  end

  it 'handles text + facet search' do
    query = 'utf8=✓&f[organization][]=Detroit+Public+Television+(MI)&search_field=all_fields&q=art'
    expect(QueryMaker.translate(query)).to eq 'organization:"Detroit Public Television (MI)" text:"art"'
  end
end
