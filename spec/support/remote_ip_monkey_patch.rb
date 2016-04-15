# From http://stackoverflow.com/questions/2996446
module ActionDispatch
  class Request
    def remote_ip_with_mocking
      test_ip = ENV['RAILS_TEST_IP_ADDRESS']

      if test_ip.nil? || test_ip.empty?
        return remote_ip_without_mocking
      else
        return test_ip
      end
    end

    alias_method_chain :remote_ip, :mocking
  end
end
