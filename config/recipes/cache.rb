Capistrano::Configuration.instance.load do
  namespace :cache_dir do

    task :symlink do
      run "rm -rf #{current_path}/tmp/cache"
      run "mkdir -p #{shared_path}/cache/"
      run "ln -sf #{shared_path}/cache/ #{current_path}/tmp/cache"
    end
    
    after 'deploy', 'cache_dir:symlink'
    after 'deploy:migrations', 'cache_dir:symlink'

  end
end