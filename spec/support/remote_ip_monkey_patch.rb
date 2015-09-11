# From http://stackoverflow.com/questions/2996446
module ActionDispatch
  class Request

    def remote_ip_with_mocking
      test_ip = ENV['RAILS_TEST_IP_ADDRESS']

      unless test_ip.nil? or test_ip.empty?
        return test_ip
      else
        return remote_ip_without_mocking
      end
    end

    alias_method_chain :remote_ip, :mocking

  end
end