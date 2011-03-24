class RssFeed < Feed

  validates_uniqueness_of :feedurl
  validates_presence_of :feed_type_id

  # ingest any entries for this feed
  def ingest
    require 'digest/md5'
    require 'rfeedparser'
    
    # keep track of any errors encountered during ingestion
    errors = ""
    uningested = 0
    duplicates = []
    duplicate_count = 0
    starttime = Time.now

    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: #{self.name} [#{self.class.name}] ingest")

    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: parsing #{self.feedurl}")
    feed = FeedParser.parse(self.feedurl)
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} END: parsing #{self.feedurl}")

    self.last_ingest = Time.now

    feed.entries.each do |f|
      # get or generate the article's UUID
      uuid = get_or_generate_uuid(f)
      
      if RssArticle.count(:all, :conditions => ["uuid = ?", uuid]) > 0
        duplicates << uuid if %w(Books Events Courses).include?(self.feed_type.name)
        duplicate_count += 1
      else
        # basic attrs
        article = RssArticle.new(:feed => self, :uuid => uuid, :title => f.title, :short_description => f.description, 
                                 :link => f.feedburner_origlink || f.link, :date => f.updated_time || Time.now)
        # computed attrs
        article.author = case
        when f.author_detail && f.author_detail.name : f.author_detail.name
        when feed.feed.author_detail && feed.feed.author_detail.name : feed.feed.author_detail.name
        when f.author : f.author
        when feed.feed.author : feed.feed.author
        else ""
        end
        
        article.full_text = f.content ? f.content.map(&:value).join : f.description
        
        # if the first tag in full_text is not a block tag, run simple_format on it
        # so it has some semblance of a structure
        unless HtmlMaid.first_tag_is_a_block_tag(article.full_text)
          article.full_text = HtmlMaid.simple_format(article.full_text)
        end
        
        # ...same with the short_description
        unless HtmlMaid.first_tag_is_a_block_tag(article.short_description)
         article.short_description = HtmlMaid.simple_format(article.short_description)
        end
        
        # clean the short description (#300)
        article.short_description = HtmlMaid.clean_short_description(article.short_description)

        # if we're dealing with a feedburner feed, clean out its nasty bits
        if article.full_text.index("feedburner")
          article.full_text = HtmlMaid.housekeeping(article.full_text)
        end
        
        # Jobs need manual help
        if feed_type.name == 'Jobs'
          article.short_description = f.jobs_location.nil? ? article.short_description : f.jobs_location
          article.author = f.jobs_company.nil? ? article.author : f.jobs_company        
        end
        
        # don't save events if they're in the past. assumes events feed is
        # repurposing the updated_time field, as is http://rss.acm.org/conferences/conferences.xml
        if feed_type.name == 'Events'
          next if article.date < Time.now.at_midnight
        end
        
        # Set Default Metadata
        article.news_opinion = news_opinion
        article.digital_library = digital_library
        article.acm_resource = acm_resource
        article.user_comments = user_comments
        article.sections = sections
        article.subjects = subjects
        
        if article.save
          # auto-approve blog posts
          article.approve! if feed_type.name == 'Blog'
        else
          uningested += 1
          errors << "#{Time.now} ERROR: Unable to save article \"#{f.title}\": "
          article.errors.each_full{|msg| errors << msg + ","}
          errors.slice!(errors.length-1, 1) # remove trailing ,
          CacmExtension::INGESTION_LOGGER.info(errors)
          errors = ""
        end
      end
    end

    errors = "#{Time.now} END:   #{self.name} [#{self.class.name}] ingest. #{feed.entries.size - duplicate_count - uningested} / #{feed.entries.size} articles ingested; #{duplicate_count} skipped; #{uningested} errors. (#{(Time.now - starttime).round} sec)\n"
    CacmExtension::INGESTION_LOGGER.info(errors)
    updated = Time.now
    self.update_attribute(:last_ingest, updated)
    Article.update_all(["updated_at = ?", updated], ["uuid IN (?)", duplicates])
  end

  def display_name
    "RSS Feed: #{feed_type.name}"
  end

private
  # method to either pull the UUID from the entry if there is one or to generate one
  # based on the feed's URL and the entry's link.
  def get_or_generate_uuid(entry)
    if entry["id"].nil?
      # no uuid came through with this entry, make one
      uuid = self.feedurl + entry.link
      # add some extra sauce to the UUID in case the event's or course's url isn't unique
      if self.feed_type.name == "Courses" || self.feed_type.name == "Events"
        uuid += entry["title"]
      end
    else
      uuid = entry["id"]
    end
    
    # return the MD5 digest of UUID
    Digest::MD5.hexdigest(uuid)
  end

end