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
              s = z.read(File.basename(filename.gsub(/\.zip$/, '')))
              z.close
              s
            end
          else
            # not zip
            f = File.open(filename)
            s = f.read
            f.close
            s
          end

    unless filename.include?('spec/fixtures') || filename.include?('spec/scripts')
      # leave my files alone!
      File.delete(filename)
    end

    str
  end
end
