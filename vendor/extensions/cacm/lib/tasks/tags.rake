namespace :cacm do
  namespace :tags do 
    desc "Load new tags from subjects"
    task(:load => :environment) do
      Article.load_tags
    end
    desc "Remove current tag set" 
    task(:destroy => :environment) do
      MetaTag.destroy_all
    end
    desc "List all of the characters used by section names"
    task(:characters => :environment) do
      titles = []
      Oracle::Article.with_section_all.each do |a| 
        titles += a.section.title.split(//)
        titles = titles.sort.uniq
      end
      puts titles.sort.join ', '
    end

  end
end
