class DLArticle < Article
  
  validates_presence_of :link
  belongs_to :source, :class_name => "Oracle::Article", :foreign_key => :oracle_id
  before_create :map_subjects
  before_save :cleanup_fck_fields
  
  delegate :keywords, :to => :source # we should be doing much more of this

  def self.retrieve(doi)
    if article = Oracle::Article.find_by_id(doi)
      # Set correct DL Article subclass for incoming article
      klass = case article.publication_id
      when CACM::PUB_ID : CacmArticle
      when CACM::QUEUE_ID : QueueArticle
      when CACM::CIE_ID : CIEArticle
      when CACM::CROSSROADS_ID : CrossroadArticle
      when CACM::E_LEARN_ID : ELearnArticle
      when CACM::NET_WORKER_ID : NetworkerArticle 
      when CACM::UBIQUITY_ID : UbiquityArticle
      else self
      end
      
      # Try to find a pre-existing copy of this article
      local_copy = DLArticle.find_by_oracle_id(doi) rescue nil
            
      if local_copy
        # was this assigned the correct class originally?
        unless klass.to_s.eql?(local_copy.class.name)
          local_copy.destroy # kill the old copy
          local = klass.new(:oracle_id => article.id) # create the correct klass
        else
          local = local_copy # correct class, just reassign the var
        end
      else # brand new article for ingestion: create the klass
        local = klass.new(:oracle_id => article.id)
      end
      
      local.title = article.title.gsub(/<br\s?\/?>/i,': ')
      local.subtitle = article.subtitle ? article.subtitle.strip : ""
      local.author = article.author_names || ''
      local.date = article.publication_date
      local.uuid = article.doi
      local.oracle_id = article.id
      local.link = article.citation_url
      local.position = article.sort_key.to_i
      local.short_description = article.abstract

      # yield for feed- or class-specific mods
      yield local if block_given?

      res = local.save
      
      # log any unsaved articles
      if !res
        # if the article couldn't be saved, record the errors
        errors = "#{Time.now} ERROR: Unable to save article \"#{local.title}\": "
        local.errors.each_full{|msg| errors << msg + ","}
        errors.slice!(errors.length-1, 1) # remove trailing ,
        CacmExtension::INGESTION_LOGGER.info(errors)
      end
      
      return local
    end
  end
  
  def source_human_name
    "From the Digital Library"
  end
  
  def refresh(session=nil)
    self.class.retrieve(self.oracle_id)
  end
  
  def doi
    "#{uuid}".split(/[\.\/]/).last
  end
  
  CACM::NON_DL_FULL_TEXT_TYPES.each do |type|
    type.gsub!(/\s+/, '_')
    define_method "has_#{type}?" do
      # swap the underscore out to find digital edition
      source.full_texts.collect(&:type).include?(type.sub("_"," "))
    end
    
    define_method "#{type}_url" do |*args|
      session = args.first
      if (s = source.full_texts.send(type))
        s.url(session)
      end
    end
  end

  def has_digital_library?
    not link.blank?
  end
  
  def citation_url(session=nil)
    link = self.link || source.citation_url
    link += "&CFID=#{session.session_id}&CFTOKEN=#{session.session_token}" if session.is_a?(Oracle::Session) and not session.client.blank?
    link
  end
  
  def fetch_dl_data
    session = Oracle::Session.new
    session.authenticate_user(:user => CACM::ADMIN_USER, :passwd => CACM::ADMIN_PASS, :ip => '127.0.0.1')
    
    if (html = source.full_texts.html || source.full_texts.htm) && session.is_a?(Oracle::Session) && session.can_access?(self)
      url = html.url(session)
      html, path = Net::HTTP.get_with_redirects(url)
      return [html, path]
    end
  end

  def vol_issue_page
    'Vol. ' +  self.issue.source.volume +
    ' No. ' + self.issue.source.number + ', ' +
    self.pages
  end
  
  def pages
    pages = [self.source.start_page, self.source.end_page].uniq.compact
    (pages.size > 1 ? 'Pages ' : 'Page ') + pages.join('-')
  end
  
  def track(args={})
    if (session = args[:request].session[:oracle]) and (fulltext = source.full_texts.send(args[:format]))
      curl = Curl::Easy.new(fulltext.url(session))
      curl.follow_location = true
      curl.http_head
    end
    super(:request => args[:request])
  end

  private

    # the text extracted via .inner_html has tabs, carriage returns, and 
    # linebreaks between words, sometimes without any actual true space 
    # character. this is an attempt to rectify the situation. there may be a 
    # better way to do this, but this seems to work just fine.
    def remove_whitespace(str="")
      str.strip.gsub(/\s+/, " ")
    end

    def map_subjects
      nodes = self.source.ccs_terms.collect(&:ccs_node)
      subjects = nodes.collect do |node|
        CACM::CCS_MAPPINGS.select { |k,v| v.include?(node) }.flatten.first
      end
      self.subject_ids = subjects.compact.uniq
    end
    
    def cleanup_fck_fields
      self.top_branding &&= self.top_branding.fck_cleanup
      self.bottom_branding &&= self.bottom_branding.fck_cleanup
    end

end