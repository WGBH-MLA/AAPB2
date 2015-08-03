# Do not build this rake task when in production environment.
if Rails && !Rails.env.production?

  require 'rspec/core/rake_task'

  desc "Run tests as if on CI server"
  task :ci do

    require 'jettywrapper'

    # Set the version of hydra-jetty we want, and download a clean copy of it.
    Jettywrapper.hydra_jetty_version = 'v8.4.0'
    Jettywrapper.clean

    # Copy config from solr_conf/ and fedora_conf/ directories to Solr and Fedora downloaded from hydra-jetty repo.
    Rake::Task['jetty:config'].invoke
    
    # Get the jetty params needed to pass to Jettywrapper.wrap() below.
    jetty_params = Jettywrapper.load_config.merge({
      # The :startup_wait value is the number of seconds Jettywrapper will wait
      # while checking to see if jetty started. A high value helps ensure Travis
      # builds don't time.
      :startup_wait=> 180
    })

    puts "Starting Jetty..."

    # Jettywrapper.wrap() will ensure jetty is started and available before
    # running the code in the block passed to it.
    error = Jettywrapper.wrap(jetty_params) do
      task = RSpec::Core::RakeTask.new(:spec)
      task.rspec_opts = '--tag ~not_on_travis'
      task.run_task(true)
    end
    raise "test failures: #{error}" if error
  end
end