Capistrano::Configuration.instance.load do
  namespace :ar_sendmail do

    desc "write ar_sendmail.conf"
    task :write_conf do
      erb = File.open(File.join(File.dirname(__FILE__), 'ar_sendmail.conf.erb'))
      result = ERB.new(erb.read).result(binding)
      put result, "#{shared_path}/ar_sendmail.conf"
      sudo "ln -nf #{shared_path}/ar_sendmail.conf /etc/ar_sendmail.conf"
    end
    after 'deploy:cold', 'ar_sendmail:write_conf'
    
    desc "Install runit directory"
    task :write_runit do
      erb = File.open(File.join(File.dirname(__FILE__), 'ar_sendmail.runit.erb'))
      result = ERB.new(erb.read).result(binding)
      put result, "#{shared_path}/ar_sendmail.runit"
      dp.write_runit('ar_sendmail')
    end
    after 'deploy:cold', 'ar_sendmail:write_runit'

    desc "Start ar_sendmail"
    task :start do
      dp.start_runit('ar_sendmail')
    end
    
    desc "Stop ar_sendmail"
    task :stop, :on_error => :continue do
      dp.stop_runit('ar_sendmail')
    end
    
    desc "Restart ar_sendmail"
    task :restart do
      dp.restart_runit('ar_sendmail')
    end
    
    desc "Check ar_sendmail queue"
    task :queue do 
      queue = capture "cd #{current_path} && ar_sendmail -e #{stage} --mailq"
      logger.info queue
    end
    
  end
end