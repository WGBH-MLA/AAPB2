require 'pathname'
require 'ostruct'

module Rails
  if !Rails.respond_to?(:root)
    def self.root
      Pathname.new(File.expand_path(File.dirname(File.dirname(__FILE__))))
    end
  end
  if !Rails.respond_to?(:env)
    def self.env
      OpenStruct.new(production?: false)
    end
  end
end