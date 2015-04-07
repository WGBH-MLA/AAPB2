require 'set'

module LinkChecker
  @@checked = Set[]
  FILENAME = File.join(File.dirname(__FILE__),'.link-check.txt')
  def self.needs_recheck?()
    !File.exists?(FILENAME) ||
      (Time.now - File.mtime(FILENAME))/(60*60*24*7) > 1
  end
  @@needs_recheck = self.needs_recheck?()
  def self.check(url)
    if @@needs_recheck && !@@checked.include?(url)
      puts "TODO: check #{url}"
      @@checked << url
      File.open(FILENAME, 'a') { |f| f.write(url) }
    end
  end
end