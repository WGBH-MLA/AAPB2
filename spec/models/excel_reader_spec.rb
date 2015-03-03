require_relative '../../app/models/excel_reader'

describe ExcelReader do

  it 'works' do
    hash = ExcelReader::read('spec/fixtures/excel/basic-excel.xml') { |row| row }
    expect(hash).to eq({
        'key_1_2_1' => ['key_1_2_1', nil, 'value_1_2_3'],
        'key_1_3_1' => ['key_1_3_1', 'value_1_3_2', 'value_1_3_3']
      })
  end

end
