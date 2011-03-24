Capistrano::Configuration.instance.load do
  namespace :radiant do
    
    desc "Updates extension assets"
    task :update_assets do
      run "cd #{current_path} && rake radiant:extensions:update_all RAILS_ENV=#{stage}"
    end
    after 'deploy:symlink', 'radiant:update_assets'
    
    desc "Migrates Radiant extensions"
    task :migrate_extensions do
      run "cd #{release_path} && rake db:migrate:extensions RAILS_ENV=#{stage}"
    end
    after 'deploy:migrate', 'radiant:migrate_extensions'

    namespace :file_system do
      desc "Loads content from file system"
      task :load_all do
        run "cd #{current_path} && rake file_system:load RAILS_ENV=#{stage}"
      end
    end
  end
  
  namespace :deploy do
    task :migrate, :roles => :db, :only => { :primary => true } do
      rake = fetch(:rake, "rake")
      rails_env = fetch(:rails_env, "production")
      migrate_env = fetch(:migrate_env, "")

      run "cd #{release_path}; #{rake} RAILS_ENV=#{rails_env} #{migrate_env} db:migrate"
    end
    
    desc "Copy local_config.sample.rb to remote/local_config.rb"
    task :copy_local_config, :roles => :app do
      put File.read(File.join(File.dirname(File.expand_path(__FILE__)), %W(.. .. vendor extensions #{application} lib local_config.sample.rb))), File.join(shared_path, 'local_config.rb')
    end
    before 'deploy:copy_local_config', 'deploy:chown_rails_root'
    after 'deploy:setup', 'deploy:copy_local_config'
    
    desc "Copy database.sample.rb to remote/database.rb"
    task :copy_database_yml, :roles => :app do
      put File.read(File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', 'config', 'database.sample.yml')), File.join(shared_path, 'database.yml')
    end
    before 'deploy:copy_database_yml', 'deploy:chown_rails_root'
    after 'deploy:setup', 'deploy:copy_database_yml'
    
    desc "Symlink necessary files into current dir"
    task :symlink_configs do
      run "ln -sf #{shared_path}/local_config.rb #{release_path}/vendor/extensions/#{application}/lib/local_config.rb"
      run "ln -sf #{shared_path}/database.yml #{release_path}/config/database.yml"
    end
    after 'deploy:update_code', 'deploy:symlink_configs'
  end
end