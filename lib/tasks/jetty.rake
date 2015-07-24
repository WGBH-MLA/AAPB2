require 'pry'
require 'rails_stub'
require 'jettywrapper'

namespace :jetty do

  desc "Copy solr config into jetty instance"
  task :config do

    # Jettywrapper.load_config is convenience method for loading
    # config/jetty.yml
    params = Jettywrapper.load_config
    
    config_filenames = ['solrconfig.xml', 'schema.xml']

    config_filenames.each do |filename|
      cmd = "cp #{File.join(Rails.root, 'solr_conf', filename)} #{params['jetty_home']}/solr/#{params['solr_core']}/conf/#{filename}"
      puts cmd # print the command to stdout
      output = `#{cmd} 2>&1` # run the command, capturing stdout and stderr
      raise output if ($? != 0) # dump the output in an exception if the exit status isn't 0
    end
  end
end