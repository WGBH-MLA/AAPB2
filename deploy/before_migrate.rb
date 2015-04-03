Chef::Log.info("Running deploy/before_migrate.rb in myapp app...")
 
execute "rake assets:precompile" do
  Chef::Log.info("Running rake assets:precompile...")
  cwd release_path
  command "bundle exec rake assets:precompile"
  environment "RAILS_ENV" => node[:deploy][:aapb][:rails_env]
end