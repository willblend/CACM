namespace :radiant do
  namespace :extensions do
    namespace :sitemap_search do
      
      desc "Runs the migration of the Sitemap Search extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          SitemapSearchExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          SitemapSearchExtension.migrator.migrate
        end
      end
    
    end
  end
end