# cron jobs go in config/cron/(daily|weekly|whatever)
# they are eval'd in the context of this cap script,
# which means you can do clever things like refer to <%= stage %>
# and it will be interpolated on the remote server upon installation

Capistrano::Configuration.instance.load do

  namespace :cron do
    desc "Install cron jobs into /shared"
    task :install do
      cron_dir = File.join(File.dirname(__FILE__), %w(.. cron))
      Dir[File.join(cron_dir, '*')].each do |f|
        frequency = File.basename(f)
        Dir[File.join(f, '*')].each do |task|
          task_path = File.join(shared_path, 'cron', frequency, File.basename(task))
          run "mkdir -p #{File.dirname(task_path)}"
          result = ERB.new(File.read(task)).result(binding)
          put result, task_path
          run "chmod +x #{task_path}"
          run "chmod ug+s #{task_path}"
        end
      end
    end
    
    desc "Link cron jobs to /etc/cron."
    task :symlink do
      capture("ls #{File.join shared_path, %w(cron)}").chomp.split.each do |dir|
        capture("ls #{File.join shared_path, 'cron', dir}").chomp.split.each do |cron|
          file = File.join(shared_path, 'cron', dir, cron)
          dest = File.join('/etc', "cron.#{dir}", cron)
          sudo "ln -sf #{file} #{dest}"
        end
      end
    end
    after 'deploy:cold', 'cron:install'
    after 'deploy:cold', 'cron:symlink'
  
    desc "Unlink all cron jobs from /etc/cron."
    task :clear_all do
      capture("ls #{File.join shared_path, %w(cron)}").chomp.split.each do |dir|
        capture("ls #{File.join shared_path, 'cron', dir}").chomp.split.each do |cron|
          dest = File.join('/etc', "cron.#{dir}", cron)
          sudo "rm -f #{dest}"
        end
      end
    end
  end
  
end