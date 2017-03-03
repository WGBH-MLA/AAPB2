class PlainOverride < Cmless
  ROOT = (Rails.root + 'app/views/plain_override').to_s
  attr_reader :body_html
end
