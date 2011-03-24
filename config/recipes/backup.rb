Capistrano::Configuration.instance.load do
  namespace :backup do
    namespace :import do

      desc "Synchronizes remote database and assets with local development environment."
      task :default do
        db
        assets
      end

      desc "Imports most recent nightly DB dump into local dev environment."
      task :db, :roles => :db do
        remote = capture("ls #{shared_path}/backups/sons/*sql.tar.bz2 -tr1 | tail -1").chomp
        local = "/tmp/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.#{application}.sql.bz2"
        logger.info "Transferring #{remote} on remote system to #{local} on local system."
        get remote, local
        system "rake db:import bz2dumpfile=#{local}"
        logger.info "Deleting #{local} locally"
        system "rm #{local}"
      end
      
      desc "Imports most recent nightly asset backup"
      task :assets, :roles => :app do
        remote = capture "ls #{shared_path}/backups/sons/*assets.tar.bz2 -tr1 | tail -1"
        local = "/tmp/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.#{application}.assets.bz2"
        logger.info "Transferring #{remote} on remote system to #{local} on local system."
        get remote.chomp, local
        system "rake assets:import outfile=#{local}"
      end
      
      desc "Imports a current DB snapshot into local dev environment."
      task :snapshot, :roles => :db do
        conf = dp.get_db_config(stage) # mmmultistage!
        user    = "-u#{conf[:username]}"
        db      = conf[:database]
        passwd  = conf[:password].nil? ? '' : "-p'#{conf[:password]}'"
        
        logger.info "Dumping #{db} on #{domain}"
        dumpfile = "/tmp/#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.#{application}.sql"
        run "mysqldump #{user} #{passwd} #{db} > #{dumpfile}"
        
        logger.info "Compressing #{dumpfile}"
        zipfile = "#{dumpfile}.tar.bz2"
        run "tar -cvjf #{zipfile} -C /tmp #{File.basename(dumpfile)}"
        
        logger.info "Retrieving #{zipfile}"
        get zipfile, zipfile
        
        system "rake db:import bz2dumpfile=#{zipfile}"
        
        logger.info "Deleting remote #{dumpfile}"
        run "rm #{dumpfile}"
        logger.info "Deleting remote #{zipfile}"
        run "rm #{zipfile}"
      end
    
    end
    
    desc "Write db-specific backup conf"
    task :write_db_config, :roles => :db do
      filename = 'db_backup.rb'
      conf     = dp.get_db_config(stage)
      user     = "-u#{conf[:username]}"
      db       = conf[:database]
      passwd   = conf[:password].nil? ? '' : "-p'#{conf[:password]}'"
      erb      = File.open(File.join(File.dirname(__FILE__), 'db_backup.erb'))
      result   = ERB.new(erb.read).result(binding)
      logger.info "Putting #{application} #{filename} conf on #{domain}"
      put result, "#{shared_path}/#{filename}"
    end
    after 'deploy:cold', 'backup:write_db_config'
    
    desc "Write app-specific asset backup conf"
    task :write_asset_config, :roles => :app do
      filename = 'asset_backup.rb'
      conf     = dp.get_db_config(stage)
      user     = "-u#{conf[:username]}"
      db       = conf[:database]
      passwd   = conf[:password].nil? ? '' : "-p'#{conf[:password]}'"
      erb      = File.open(File.join(File.dirname(__FILE__), 'asset_backup.erb'))
      result   = ERB.new(erb.read).result(binding)
      logger.info "Putting #{application} #{filename} conf on #{domain}"
      put result, "#{shared_path}/#{filename}"
    end
    after 'deploy:cold', 'backup:write_asset_config'
    
  end
end