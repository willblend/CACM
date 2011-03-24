namespace :radiant do
  namespace :extensions do
    namespace :ar_mailer do
      
      desc "Runs the migration of the Ar Mailer extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          ArMailerExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          ArMailerExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Ar Mailer to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[ArMailerExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(ArMailerExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
