namespace :radiant do
  namespace :extensions do
    namespace :workflow do
      
      desc "Runs the migration of the Workflow extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          WorkflowExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          WorkflowExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Workflow to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from #{WorkflowExtension.root}/public/"
        Dir[WorkflowExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(WorkflowExtension.root, '')
          directory = File.dirname(path)
          FileUtils.mkdir_p RAILS_ROOT + directory
          FileUtils.cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
