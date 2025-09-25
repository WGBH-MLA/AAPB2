require_relative '../lib/rails_stub'
require 'webmock'

ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.

  RSpec::Expectations.configuration.on_potential_false_positives = :nothing

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    # Disable WebMock by default, and be sure to re-enable it before using it.
    WebMock.disable!
  end

  config.after(:suite) do
    # only run this where the mailer class is available
    if Object.const_defined?('Notifier')
      run_linkchecker = YAML.load(ERB.new(File.new(Rails.root + 'config/aws_ses.yml').read).result)['run_linkchecker']
      Notifier.link_checker_report if run_linkchecker
    end
  end
end
