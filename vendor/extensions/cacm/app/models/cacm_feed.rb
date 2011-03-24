class CacmFeed < Feed
  def ingest
    starttime = Time.now
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: #{self.name} [#{self.class.name}] ingest")
    latest = CacmArticle.maximum :oracle_id
    latest_date = CacmArticle.find_by_oracle_id(latest).source.created_date

    articles = Oracle::Article.find(:all,
                                    :select => 'id',
                                    :conditions => ["created_date > ? AND publication_id = ?",
                                                    latest_date,
                                                    CACM::PUB_ID],
                                    :order => "sort_key ASC")
    articles.each do |article|
      CacmArticle.retrieve(article.id)
    end

    self.last_ingest = Time.now
    self.save
    
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} END:   #{self.name} [#{self.class.name}] ingest (#{(Time.now - starttime).round} sec)\n")
    
  end

  def display_name
    "(CACM Articles)"
  end

end