require 'pathname'

module Rails
  if !Rails.respond_to?(:root)
    def self.root
      Pathname.new(File.dirname(File.dirname(__FILE__)))
    end
  end
end