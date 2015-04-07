require 'set'

module LinkChecker
  @@checked = Set[]
  FILENAME = File.join(File.dirname(__FILE__),'.link-check.txt')
  RE_IGNORES = [
    /^\/catalog\?/, # to many combos
    /^https?:/, # TODO: remote sites
    /#/ # TODO: anchors
  ]
  def self.needs_recheck?()
    return true if !File.exists?(FILENAME)
    if (Time.now - File.mtime(FILENAME))/(60*60*24*7) > 1
      File.unlink(FILE)
      return true
    end
    return false
  end
  @@needs_recheck = self.needs_recheck?()
  def self.check(url)
    return unless @@needs_recheck
    return if @@checked.include?(url)
    return if RE_IGNORES.map{|ignore| ignore.match(url)}.any?

    fail("relative links are trouble: #{url}") if /^[^\/]/.match(url)
    # TODO: try fetching with capybara
    @@checked << url
    File.open(FILENAME, 'a') { |f| f.write(url) }
  end
end