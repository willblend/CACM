namespace :purger do
  desc "Purge (archive) all rejected articles more than 30 days old"
  # note - we're not really 'purging' the articles so much as changing their state to 'archived'.
  # this is so in case we have some old, rejected articles that still happen to be in the feed so
  # those articles don't get reingested.  (see #538)
  task(:purge_old_articles => :environment) do
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: purger:purge_old_articles (Archiving rejected articles that are over 30 days old.)")
    Article.find(:all, :conditions => ['state = ? AND updated_at < ?', 'rejected', 30.days.ago]).each do |a|
      # keep track of what we throw away
      CacmExtension::INGESTION_LOGGER.info("#{Time.now} ARCHIVED: #{a.id} - #{a.title} (#{a.feed.name})")
      a.archive!
    end
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} END: purger:purge_old_articles\n")
    CacmExtension::INGESTION_LOGGER.flush
  end
  
  desc "Purge any items not present in Books, Courses, and Conferences feeds anymore"
  task(:purge_nonexistent_articles => :environment) do
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: purger:purge_nonexistent_articles (Purging nonexistent articles from Books, Courses, and Conferences feeds.)")
    Feed.find(:all).each do |f|
      if %w(Books Events Courses).include?(f.feed_type.name)
        Article.find(:all, :conditions => ['feed_id = ? AND updated_at < ?', f.id, f.last_ingest]).each do |a|
          # keep track of what we throw away
          CacmExtension::INGESTION_LOGGER.info("#{Time.now} DELETED: #{a.id} - #{a.title} (#{a.feed.name})")
          a.destroy
        end
      end
    end
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} END: purger:purge_nonexistent_articles\n")
    CacmExtension::INGESTION_LOGGER.flush
  end

  desc "Purge old hits"
  task(:purge_old_hits => :environment) do
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: purger:purge_old_hits")
    Hit.find(:all, :select => 'id', :conditions => ['created_at < (?)',1.month.ago]).map(&:destroy)
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} END: purger:purge_old_hits\n")
    CacmExtension::INGESTION_LOGGER.flush
  end

end