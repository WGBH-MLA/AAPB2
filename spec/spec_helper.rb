require_relative '../lib/rails_stub'
require 'webmock'

RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
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
    require('csv')
    filename = "link_checker_result_#{Time.now.strftime('%m.%d.%Y')}.csv"
    if File.exists?(filename)
      # EMAIL that files!
      num_links = CSV.read(filename).length
      email = Notifier.send_link_checker_report(Rails.root+filename, num_links).deliver
      File.delete(filename)
    else
      Notifier.send_link_checker_clear.deliver
    end

  end
end
