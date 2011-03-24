namespace :radiant do
  namespace :extensions do
    namespace :fck_shards do
      
      desc "Runs the migration of the Fck Shards extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          FckShardsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          FckShardsExtension.migrator.migrate
        end
      end
      desc "Copies FCK Shards assets to the public directory"
      task :update => :environment do
        is_svn = proc {|path| path =~ /\.svn/ }
        is_dir = proc {|path| File.directory?(path) }
        puts "Copying assets from #{FckShardsExtension.root}/public/"
        Dir[FckShardsExtension.root + "/public/**/*"].reject(&is_svn).reject(&is_dir).each do |file|
          path = file.sub(FckShardsExtension.root, '')
          directory = File.dirname(path)
          FileUtils.mkdir_p RAILS_ROOT + directory
          FileUtils.cp file, RAILS_ROOT + path
        end
      end      
    end
  end
end