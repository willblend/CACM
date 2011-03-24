namespace :ingester do
  desc "Ingest all active feeds"
  task(:ingest_all => :environment) do
    # maximum duration an ingest task for a feed can run for before sending an error
    MAX_HOURLY = 600 # hourly = max 10 minutes / feed (in case a new CACM issue comes through- takes a bit longer to parse than typical feeds)
    MAX_DAILY = 900 # daily = max 15 minutes / feed
    ThinkingSphinx.deltas_enabled = false
    @feed = Feed.find(:all)
    frequency = ENV['frequency'] || 'hourly'
    starttime = Time.now
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: #{frequency} ingester:ingest_all")
    @feed.each do |f|
      if f.active && f.class_name != 'ManualFeed'
        # only ingest books, events, and courses daily since ingesting these feeds are more db-intensive (see tix #243, #577)
        if %w(Books Events Courses).include?(f.feed_type.name)
          if frequency == 'daily'
            feedstart = Time.now
            f.ingest
            if (Time.now-feedstart) > MAX_DAILY 
              # send email!
              IngestionNotifier.deliver_notification(f.name, (Time.now-feedstart).round, 'Daily')
            end            
          end
        elsif frequency == 'hourly'
          feedstart = Time.now
          f.ingest
          if (Time.now-feedstart) > MAX_HOURLY
            # send email!
            IngestionNotifier.deliver_notification(f.name, (Time.now-feedstart).round, 'Hourly')
          end          
        end
      end
    end
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} END: #{frequency} ingester:ingest_all (#{(Time.now - starttime).round} sec)")
    CacmExtension::INGESTION_LOGGER.flush
    Rake::Task['ts:in'].invoke
  end

end