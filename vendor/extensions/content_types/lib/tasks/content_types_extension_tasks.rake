namespace :radiant do
  namespace :extensions do
    namespace :content_types do
      
      desc "Runs the migration of the ContentTypes extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          ContentTypesExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          ContentTypesExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the ContentTypes to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from #{ContentTypesExtension.root}/public/"
        Dir[ContentTypesExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(ContentTypesExtension.root, '')
          directory = File.dirname(path)
          FileUtils.mkdir_p RAILS_ROOT + directory
          FileUtils.cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
