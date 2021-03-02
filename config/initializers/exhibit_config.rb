require 'yaml'
require 'pry'

Rails.application.configure do
  config.exhibits = YAML.load_file(Rails.root + 'config/exhibits.yml')
end