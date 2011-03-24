Capistrano::Configuration.instance.load do

  namespace :deploy do 
    desc "Restarting Passenger with restart.txt" 
    task :restart, :roles => :app, :except => { :no_release => true } do 
      run "touch #{current_path}/tmp/restart.txt" 
    end 
 
    desc "Take site down with deploy:web:disable" 
    task :stop, :roles => :app do 
      deploy.web.disable unless dp.file_exists?("#{current_path}/public/system/maintenance.html")
    end 
 
    desc "Put site up with deploy:web:enable" 
    task :start, :roles => :app do
      deploy.web.enable if dp.file_exists?("#{shared_path}/system/maintenance.html")
      deploy.restart
    end
  end

end