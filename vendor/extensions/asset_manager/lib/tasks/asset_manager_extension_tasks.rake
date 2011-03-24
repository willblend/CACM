namespace :radiant do
  namespace :extensions do
    namespace :asset_manager do
      
      desc "Runs the migration of the Asset Manager extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          AssetManagerExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          AssetManagerExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Asset Manager to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from #{AssetManagerExtension.root}/public/"
        Dir[AssetManagerExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(AssetManagerExtension.root, '')
          directory = File.dirname(path)
          FileUtils.mkdir_p RAILS_ROOT + directory
          FileUtils.cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
