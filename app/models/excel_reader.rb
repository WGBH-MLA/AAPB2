require 'rexml/document'
require 'rexml/xpath'

module ExcelReader
  def self.read(path, key_column=0)
    doc = REXML::Document.new(File.read(path))
    row_number = 0
    Hash[
      REXML::XPath.match(doc, '/Workbook/Worksheet[1]/Table/Row').map do |row|
        row_number += 1
        if row_number == 1
          nil
        else
          params = []
          index = 0
          REXML::XPath.match(row, 'Cell/Data').each do |data|
            index_attribute = data.parent.attributes['Index']
            if index_attribute
              index = index_attribute.to_i # 1-based
            else
              index += 1
            end
            params[index-1] = data.text
          end
          key = params[key_column]
          begin
            value = yield(params)
          rescue ArgumentError => e
            raise ArgumentError.new(e.message + " Row #{row_number}. #{params}. #{row}")
          end
          [key,value]
        end
      end.select { |x| x }
    ]
  end
end
