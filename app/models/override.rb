class Override < Cmless
  ROOT = File.expand_path('../views/override', File.dirname(__FILE__))
  attr_reader :body_html
end