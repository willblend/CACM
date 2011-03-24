Capistrano::Configuration.instance.load do
  namespace :thinking_sphinx do
    
    desc "Install runit directory"
    task :write_runit do
      erb = File.open(File.join(File.dirname(__FILE__), 'searchd.runit.erb'))
      result = ERB.new(erb.read).result(binding)
      put result, "#{shared_path}/searchd.runit"
      dp.write_runit('searchd')
    end
    after 'deploy:cold', 'thinking_sphinx:write_runit'

    desc "Start thinking_sphinx"
    task :start do
      dp.start_runit('searchd')
    end
    
    desc "Stop thinking_sphinx"
    task :stop, :on_error => :continue do
      dp.stop_runit('searchd')
    end
    
    desc "Restart thinking_sphinx"
    task :restart do
      dp.restart_runit('searchd')
    end
    
    desc "Rebuild thinking_sphinx index"
    task :index do
      run "cd #{current_path} && rake #{stage} ts:in"
    end
    
    desc "Write sphinx.conf file"
    task :config do
      unless dp.file_exists? File.join(current_path, 'config', "#{stage}.sphinx.conf")
        run "cd #{current_path} && rake #{stage} ts:config"
      end
    end
    
    desc "Set up shared/sphinx"
    task :make_dir do
      run "mkdir -p #{shared_path}/sphinx"
    end
    after 'deploy:setup', 'thinking_sphinx:make_dir'

    desc "Symlink sphinx dir"
    task :symlink do
      run "rm -rf #{current_path}/db/sphinx"
      run "ln -sf #{shared_path}/sphinx/ #{current_path}/db/"
    end
    
    desc "Make Sphinx indexes readable"
    task :permissions, :on_error => :continue do
      sudo "chown -R #{user}:#{group} #{shared_path}/sphinx #{current_path}/config/#{stage}.sphinx.conf"
    end
    
    before 'thinking_sphinx:index', 'thinking_sphinx:config'

    before 'thinking_sphinx:start', 'thinking_sphinx:symlink'
    before 'thinking_sphinx:index', 'thinking_sphinx:symlink'
    
    after 'deploy', 'thinking_sphinx:index', 'thinking_sphinx:restart'
    after 'deploy:migrations', 'thinking_sphinx:index', 'thinking_sphinx:restart'
    
    
    before 'thinking_sphinx:stop', 'thinking_sphinx:permissions'
    before 'thinking_sphinx:index', 'thinking_sphinx:permissions'
  end
end