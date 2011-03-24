class Oracle::Article < Oracle
  PUBLICATION_ID = 'J79'
  set_table_name 'dldata.articles'
  belongs_to :issue
  belongs_to :publication
  belongs_to :section
  has_one :local, :class_name => "::Article", :foreign_key => :oracle_id
  has_many :full_texts, :foreign_key => :id, :extend => CACM::FullTextExtensions
  has_many :supplements, :foreign_key => :id, :order => "url DESC"
  has_many :article_terms, :class_name => 'Oracle::ArticleTerm', :foreign_key => :id, :order => :ccs_node
  has_many :ccs_terms, :class_name => 'Oracle::CCSTerm', :through => :article_terms, :uniq => true, :order => 'dldata.ccs_lookup.ccs_node', :extend => CACM::CCSTermExtension
  has_many :inclusions, :foreign_key => :id
  has_many :reviews, :foreign_key => :id
  alias_attribute :keywords, :ccs_terms
  has_finder :with_section, :conditions=>['section_id is not null']

  global_scope(:cacm_articles_only, :find=>{:conditions=>["dldata.articles.publication_id = ?", PUBLICATION_ID]})
  
  def citation_url(session=nil)
    if session.is_a?(Oracle::Session) and not session.client.blank?
      self[:citation_url] + "&CFID=#{session.session_id}&CFTOKEN=#{session.session_token}"
    else
      self[:citation_url]
    end
  end

  def self.with_section_all
    Oracle::Article.with_section.find(:all)
  end

  def self.load_tags 
    puts "Loading tags"
    Oracle::Article.with_section_all.each(&:update_meta_tags)
  end

  def update_meta_tags
    return unless section
    a = ::Article.find_by_oracle_id(id)
    if a
      a.meta_tags = section.title_as_tag 
    end
  end	
end
