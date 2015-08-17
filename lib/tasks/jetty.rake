require 'jettywrapper'

namespace :jetty do
  desc 'Copy solr config into jetty instance'
  task :config do
    # Jettywrapper.load_config is convenience method for loading
    # config/jetty.yml
    params = Jettywrapper.load_config

    src_dir = File.join(Rails.root, 'solr_conf')
    dest_dir = "#{params['jetty_home']}/solr/#{params['solr_core']}/conf"

    FileUtils.mkdir_p(dest_dir, verbose: true)
    FileUtils.cp_r("#{src_dir}/.", dest_dir, verbose: true)
  end
end
