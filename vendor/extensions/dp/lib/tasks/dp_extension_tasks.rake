namespace :radiant do
  namespace :extensions do
    namespace :dp do
      
      desc "Runs the migration of the Dp extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          DpExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          DpExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Dp to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from #{DpExtension.root}/public/"
        Dir[DpExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(DpExtension.root, '')
          directory = File.dirname(path)
          FileUtils.mkdir_p RAILS_ROOT + directory
          FileUtils.cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
