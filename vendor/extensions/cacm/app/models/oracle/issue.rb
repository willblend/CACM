class Oracle::Issue < Oracle
  # Exclude these Oracle Issues representing Electronic Supplements from being queried
  ES_EXCLUSIONS = [352515,276404,272682]

  set_table_name 'dldata.issues'
  has_one :local, :class_name => "::Issue", :foreign_key => :issue_id
  has_many :articles, :class_name => 'Oracle::Article', :order => 'dldata.articles.sort_key'
  has_many :sections, :order => :sort_key, :extend => CACM::SectionExtensions
  has_many :full_texts, :foreign_key => :id, :extend => CACM::FullTextExtensions
  belongs_to :publication
  set_date_columns :pub_date rescue nil # test env hack

  alias_attribute :number, :issue

  def self.year(year)
    self.find(:all, 
              :conditions => ['publication_id = ? AND EXTRACT(YEAR FROM pub_date) = ? AND id NOT IN (?)', CACM::PUB_ID, year, ES_EXCLUSIONS],
              :order => "pub_date DESC")
  end

  def citation_url(session=nil)
    if session.is_a?(Oracle::Session) and not session.client.blank?
      self[:citation_url] + "&CFID=#{session.session_id}&CFTOKEN=#{session.session_token}"
    else
      self[:citation_url]
    end
  end

  def previous
    @previous ||= self.class.find(:first,
                                  :conditions => ['publication_id = ? AND pub_date < ? AND id NOT IN (?)', self.publication_id, self.pub_date, ES_EXCLUSIONS],
                                  :order => 'pub_date DESC')
  end

  def next
    @next ||= self.class.find(:first,
                              :conditions => ['publication_id = ? AND pub_date > ? AND id NOT IN (?)', self.publication_id, self.pub_date, ES_EXCLUSIONS], 
                              :order => 'pub_date ASC')
  end
end