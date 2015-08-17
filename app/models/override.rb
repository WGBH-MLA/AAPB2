class Override < Cmless
  ROOT = (Rails.root + 'app/views/override').to_s
  attr_reader :body_html
end
