class DLFeed < Feed
  
  def ingest(id=nil)
    CacmExtension::INGESTION_LOGGER.info("#{Time.now} BEGIN: #{self.name} [#{self.class.name}] ingest")
    return if id.blank?
    if upstream = Oracle::Article.find_by_id(id, :select => 'publication_id')
      klass = case upstream.publication_id
        when CACM::PUB_ID         : CacmArticle
        when CACM::QUEUE_ID       : QueueArticle
        when CACM::CIE_ID         : CIEArticle
        when CACM::CROSSROADS_ID  : CrossroadArticle
        when CACM::E_LEARN_ID     : ELearnArticle
        when CACM::NET_WORKER_ID  : NetworkerArticle 
        when CACM::UBIQUITY_ID    : UbiquityArticle
      end
    end
    klass ||= DLArticle
    if local = klass.retrieve(id) do |article|
        article.feed_id = self.id
      end
      self.last_ingest = Time.now
      self.save
      CacmExtension::INGESTION_LOGGER.info("#{Time.now} END:   #{self.name} [#{self.class.name}] ingest")
      return local
    end
  end

  def display_name
    '(DL Articles)'
  end

end