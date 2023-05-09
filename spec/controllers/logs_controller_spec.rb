require 'rails_helper'

describe LogsController do
  before :all do
    @log_dir = Dir.mktmpdir("test_logs_")
    Dir.chdir(@log_dir) do
      2.times do |n|
        content = "sample log entry for log file #{n}"
        File.write("#{@log_dir}/test_log_file_#{n}.log", content)
      end
    end

    @empty_log_dir = Dir.mktmpdir("test_logs_empty_")
  end

  context 'when there are no log files present' do
    # Set the LOG_DIR to an new temporary empty directory.
    before { LogsController.log_dir = @empty_log_dir }

    describe 'GET /logs' do
      before { get :index }
      it 'displays a message indicating there are no log files' do
        expect(response.body).to include LogsController.no_log_files_found_msg
      end
    end
  end

  context 'when there are log files present' do
    before { LogsController.log_dir = @log_dir }

    let(:test_log_file_paths) { Dir["#{LogsController.log_dir}/**/*"] }

    describe 'GET /logs' do
      before { get :index }
      it 'displays a list of all logs' do
        test_log_file_paths.each do |log_file_path|
          expect(response.body).to include(File.basename(log_file_path))
        end
      end
    end

    describe 'GET /logs/[:log_file_name]' do
      # Grab a sample log file to write to.
      let(:test_log_file_path) { test_log_file_paths.sample }
      # Get the test log filename (not full path) to use in the URL.
      let(:test_log_file_name) { File.basename(test_log_file_path) }
      let(:test_log_content) { File.read(test_log_file_path) }

      it 'displays the log file contents' do
        get :show, log_file_name: test_log_file_name
        expect(response.body).to include test_log_content
      end

      context 'when the file you are looking for is explicitly ignored' do
        # SETUP: Add our test_log_file_name to the list of files to be ignored.
        before { LogsController.ignore << test_log_file_name }

        it 'returns a 403' do
          get :show, log_file_name: test_log_file_name
          expect(response.status).to eq 403
        end
      end
    end
  end
end
