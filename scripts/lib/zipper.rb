require 'zip'

module Zipper
  def self.write(filename, content)
    Zip::File.open(filename+'.zip', Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream(File.basename(filename)) { |stream| stream << content }
    end
  end
  def self.read(path)
    filename = path.to_s
    plain_name = filename.gsub(/\.zip$/, '')
    zip_name = filename =~ /\.zip$/ ? filename : filename + '.zip'
    if File.exists?(zip_name)
      Zip::File.open(zip_name, Zip::File::CREATE) do |z|
        z.read(File.basename(plain_name))
      end
    else
      File.read(filename)
    end
  end
end
