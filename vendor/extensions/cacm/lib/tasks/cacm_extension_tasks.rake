desc "Set the environment variable RAILS_ENV='sandbox'."
task :cache do
  ENV['RAILS_ENV'] = RAILS_ENV = 'cache'
  Rake::Task[:environment].invoke
end

namespace :radiant do
  namespace :extensions do
    namespace :cacm do
      
      desc "Runs the migration of the Cacm extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          CacmExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          CacmExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Cacm to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from #{CacmExtension.root}/public/"
        Dir[CacmExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(CacmExtension.root, '')
          directory = File.dirname(path)
          FileUtils.mkdir_p RAILS_ROOT + directory
          FileUtils.cp file, RAILS_ROOT + path
        end
        
        # Create cacm.js file from defined JS libraries
        javascript_files = ['prototype_compressed.js','validation_compressed.js','lowpro_compressed.js','site_compressed.js']
        
        File.open(File.join(RAILS_ROOT + "/public/javascripts/cacm_scripts.js"), 'w+') do |js|
          # load and concatenate js files from the root js directory
          javascript_files.each do |lib|
            js << "// -------------------------- #{lib}\n\n"
            js << IO.read(RAILS_ROOT + "/public/javascripts/#{lib}")
            js << "\n\n"
            print "Added javascript file \"#{lib}\" to cacm_scripts.js.\n"
          end
        end
        
      end  
    end
  end
end
