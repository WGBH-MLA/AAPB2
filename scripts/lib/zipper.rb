require 'zip'

module Zipper
  def self.write(filename, content)
    Zip::File.open(filename+'.zip', Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream(File.basename(filename)) { |stream| stream << content }
    end
  end
  def self.read(filename)
    Zip::File.open(filename+'.zip', Zip::File::CREATE) do |zipfile|
      zipfile.read(File.basename(filename))
    end
  rescue
    # Fallback
    File.read(filename)
  end
end
