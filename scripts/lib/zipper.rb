require 'zip'

module Zipper
  def self.write(filename, content)
    Zip::File.open(filename + '.zip', Zip::File::CREATE) do |zipfile|
      zipfile.get_output_stream(File.basename(filename)) { |stream| stream << content }
    end
  end

  def self.read(path)
    filename = path.to_s

    str = if filename =~ /\.zip$/

      # zipper
      Zip::File.open(filename, Zip::File::CREATE) do |z|
        str = z.read( File.basename( filename.gsub(/\.zip$/, '') ) )
        z.close
      end

      str
    else
      # not zip
      f = File.open(filename)
      str = f.read
      f.close
      str
    end

    unless filename.include?('spec/fixtures') || filename.include?('spec/scripts')
      File.delete(filename)
    end

    str
  end

end
