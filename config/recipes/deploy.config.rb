Capistrano::Configuration.instance.load do
  namespace :deploy do
    namespace :configure do
      
      after 'deploy:setup', 'deploy:chown_rails_root'

      desc "Write site-specific Apache conf"
      task :write_apache_conf, :roles => :web do
        erb = File.open(File.join(File.dirname(__FILE__), 'apache.conf.erb'))
        result = ERB.new(erb.read).result(binding)
        logger.info "Putting #{application}.conf.common on #{domain}"
        put result, "#{shared_path}/#{application}.conf.common"
        main = <<-EOF
<VirtualHost *:80>
  include #{shared_path}/#{application}.conf.common
</VirtualHost>
        EOF
        put main, "#{shared_path}/#{application}.conf"
        sudo "cp #{shared_path}/#{application}.conf /etc/httpd/conf.d/#{application}.conf"
        sudo "rm #{shared_path}/#{application}.conf"
        sudo "/sbin/service httpd graceful"
      end
      after 'deploy:setup', 'deploy:configure:write_apache_conf'
  
      desc "Write sites-specific logrotate file"
      task :write_log_rotate, :roles => :app do
        erb = File.open(File.join(File.dirname(__FILE__), 'logrotate.erb'))
        result = ERB.new(erb.read).result(binding)
        logger.info "Putting #{application} logrotate on #{domain}"
        put result, "#{shared_path}/logrotate.#{application}"
        # logrotate must be hard link to run on CentOS/RHEL
        sudo "ln -f #{shared_path}/logrotate.#{application} /etc/logrotate.d/#{application}"
      end
      after 'deploy:setup', 'deploy:configure:write_log_rotate'

    end
  end
end