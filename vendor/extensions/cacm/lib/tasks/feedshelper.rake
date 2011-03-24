namespace :feedshelper do
  desc "Load all feeds from feeds.yml into the app."
  task(:load_feeds => :environment) do
    require 'yaml'
    @feeds = YAML::load(File.open("#{CacmExtension.root}/lib/feeds.yml"))
    @feeds.each do |f|

      if f["class_name"] == "DigitalLibraryFeed"
        feed = DigitalLibraryFeed.new({:name => f["name"]})
      elsif f["class_name"] == "ManualFeed"
        feed = ManualFeed.new({:name => f["name"]})
      else
        ft = FeedType.find(:first, :conditions => ["name = ?", "#{f["feedtype"]}"])
        feed = RssFeed.new({:name => f["name"], :feedurl => f["feedurl"], :feed_type_id => ft[:id]})
      end
      feed.save
    end
  end

  desc "Check all the feeds in feeds.yml for what they do and don\'t provide"
  task(:check_feeds) do
    require 'yaml'
    require 'rfeedparser'
    @feeds = YAML::load(File.open("#{RAILS_ROOT}/vendor/extensions/cacm/lib/feeds.yml"))
    results = "Feed Title,Feed URL,Feed Version,Bozo,Entry Title,Entry Link,Entry Description,Entry UUID,Entry Updated Time,Entry Author,Entry Full Text,All Entry Fields\n"
  
    @feeds.each do |f|
      if (f["feedurl"])
        e = FeedParser::parse(f["feedurl"])
        #print "now parsing " + e.feed.title + "\n"
        results << "#{e.feed.title},#{f["feedurl"]},#{e.version},"
        results << (e.bozo ? "true" : "false") + ","
        results << (e.entries[0].title.nil? ? "false" : e.entries[0].title) + ","
        results << (e.entries[0].link.nil? ? "false" : e.entries[0].link) + ","
        results << (e.entries[0].description.nil? ? "false" : "true") + ","
        results << (e.entries[0]["id"].nil? ? "false" : "#{e.entries[0]["id"]}") + ","
        results << (e.entries[0].updated_time.nil? ? "false" : "#{e.entries[0].updated_time}") + ","
        results << (e.entries[0].author.nil? ? "false" : e.entries[0].author) + ","
        results << (e.entries[0].content.nil? ? "false" : "true") + ","
        e.entries[0].each do |field|
          results << field[0] << " "
        end
        results << "\n"
      end
    end
    
    print results
    
  end

  desc "Load an example article from each Feed and look at it's full text"
  task(:check_full_text => :environment) do
    RssFeed.find(:all).each do |r|
      a = Article.find(:first, :conditions => ['feed_id = ?', r[:id]])
      if (a)
        print "FEED NAME: " + r.name + "\n"
        print "FEED URL: " + r.feedurl + "\n"
        print "=======DESCRIPTION=========\n"
        print a.short_description + "\n"
        print "=======FULL TEXT=========\n"
        print a.full_text + "\n"
        print "====================================\n\n"
      end
    end
  end

  desc "Search articles for all occurrences of 'img'"
  task(:find_imgs => :environment) do
    a = Article.search("img")
    a.each do |b|
      print b.feed.name + "\n"
      print b.feed.feedurl + "\n"
      print b.title + "(#{b[:id]})\n"
      print b.short_description + "\n"
      print b.full_text + "\n"
    end
  end
  
  desc "Search all short descriptions for occurrences of 'img'"
  task(:find_imgs_in_short_descriptions => :environment) do
    images = 0
    Article.find(:all, :order => :feed_id).each do |a|
      if a.short_description =~ /<img?[^>]*>/
        print ("#{a.feed.name}: #{a.id} - #{a.title}\t \n")
        images += 1
      end
    end
    print("#{images} short descriptions with IMG tags\n")
  end
  
  desc "clean short descriptions"
  task(:clean_short_descriptions => :environment) do
    ThinkingSphinx.deltas_enabled = false
    updated = 0
    Article.find(:all).each do |a|
      if a.short_description =~ /<img?[^>]*>/
        a.short_description = HtmlMaid.clean_short_description(a.short_description)
        res = a.save
        if res
          print("updated #{a.id}\n")
          updated += 1
        else
          print("UNABLE TO SAVE #{a.id}")
        end
      end
    end
    print("updated #{updated} short descriptions.\n")
    Rake::Task['ts:in'].invoke
  end
  
  desc "Load all categories from categories.yml into the app."
  task(:load_feed_types => :environment) do
    require 'yaml'
    @feed_types = YAML::load(File.open("#{CacmExtension.root}/lib/feed_types.yml"))
    @feed_types.each do |f|
      ft = FeedType.new({:name => f["name"]})
      ft.save
    end
  end

  desc "Load all sections from sections.yml into the app."
  task(:load_sections => :environment) do
    require 'yaml'
    @sections = YAML::load(File.open("#{CacmExtension.root}/lib/sections.yml"))
    @sections.each do |f|
      ft = Section.new({:name => f["name"]})
      ft.save
    end
  end
  
  desc "Load all subjects from subjects.yml into the app."
  task(:load_subjects => :environment) do
    require 'yaml'
    @subjects = YAML::load(File.open("#{CacmExtension.root}/lib/subjects.yml"))
    @subjects.each do |s|
      sb = Subject.find_or_create_by_name(:name => s["name"])
      sb.keywords.clear
      sb.save
      s['keywords'].each { |k| sb.keywords << k } if s['keywords']
    end
    # clean out any keywords that lost all associations
    Keyword.delete(Keyword.find_by_sql 'select * from keywords left join keywords_subjects on keywords.id = keyword_id where subject_id is null')
  end
  
  desc "Randomly populate Subjects and Sections"
  task(:populate_subjects_and_sections => :environment) do
    s = Subject.find(:all)
    idx = 0
    Article.find(:all).chunk(Subject.count).each do |article|
      article.each do |a|
        a.subjects << s[idx]
      end
      idx += 1
    end
    
    s = Section.find(:all)
    idx = 0
    Article.find(:all).chunk(Section.count).each do |article|
      article.each do |a|
        a.sections << s[idx]
        a.approve!
        a.save
      end
      idx += 1
    end
    
  end
  
  desc "Report on any unsavable articles.  Repent now!"
  task(:find_unsavable_articles => :environment) do
    report = "UNSAVABLE ARTICLES\n\n"
    i = 0
    Article.find(:all).each do |a|
      if a.save
        # do nothing
      else
        i = i + 1
        report << "\t#{a.id} - #{a.title} (#{a.errors.inspect})\n"
      end
    end
    report << "\n------------------------\nTOTAL: #{i} unsavable articles found.\n"
    print report
  end
  
  desc "Report on any unsavable articles by feed.  Repent now!"
  task(:find_unsavable_articles_by_feed => :environment) do
    report = "UNSAVABLE ARTICLES BY FEED\n\n"
    i = 0
    j = 0
    Feed.find(:all).each do |f|
      j = 0
      ids = ""
      f.articles.each do |a|
        if a.save
          # do nothing
        else
          i = i + 1
          j = j + 1
          ids << "#{a.id},"
        end
      end
      if j > 0
        report << "\t#{f.name} has #{j} / #{f.articles.size} unsavable articles: (#{ids})\n"
      end
    end
    report << "\n------------------------\nTOTAL: #{i} unsavable articles found.\n"
    print report
  end  
  
  desc "Report any conflicts between Radiant page titles for the browse by subject subpages and Subject names"
  task(:subject_compatibility_report => :environment) do
    report = ""
    Page.find_by_slug("browse-by-subject").children.each do |s|
      if Subject.find_by_name(s.title).nil?
        report << "Unable to find Subject with name #{s.title}\n"
      end
    end
    Subject.find(:all).each do |s|
      if Page.find_by_title(s.name).nil?
        report << "No page found with title #{s.name}"
      end
    end
    
    if report == ""
      print "Subjects look good.\n"
    else
      print "Problems found:\n#{report}"
    end
  end
  
  desc "Convert RSS Feed UUIDs to hash-based"
  task(:convert_to_hash_based_uuids => :environment) do
    require 'digest/md5'
    i = 0
    ThinkingSphinx.deltas_enabled = false
    starttime = Time.now
    RssFeed.find(:all).each do |f|
      f.articles.each do |a|
        a.uuid = Digest::MD5.hexdigest(a.uuid)
        res = a.save
        if res
          i += 1
        else
          print("*** unable to save #{a.id} - #{a.title}\n")
        end
      end
    end
    
    print("updated #{i} articles (#{(Time.now - starttime).round} sec).\n")
    Rake::Task['ts:in'].invoke
    
  end
  
end