class Article < ActiveRecord::Base
  set_inheritance_column :class_name

  attr_readonly :comments_counter

  belongs_to :feed
  has_and_belongs_to_many :sections, :order => :position
  has_and_belongs_to_many :subjects
  belongs_to_asset :image
  
  validates_uniqueness_of :uuid
  validates_presence_of :uuid, :title, :date, :feed_id

  trackable_resource
  listable_resource :index_search_field => 'title',
    :searchable_fields  => %w( title date ),
    :filter_field => 'state',
    :sortable_fields  => ["COUNT(comments.id) DESC","RAND()","RAND(), approved_at DESC","position", "position ASC", "position DESC", "articles.position", "articles.position ASC", "articles.position DESC", "title", "title ASC", "title DESC", "articles.title", "articles.title ASC", "articles.title DESC", "date", "date ASC", "date DESC", "date DESC, approved_at DESC", "articles.date", "articles.date ASC", "articles.date DESC", "feed_id", "feed_id ASC", "feed_id DESC", "articles.feed_id", "articles.feed_id ASC", "articles.feed_id DESC", "approved_at", "approved_at ASC", "approved_at DESC", "articles.approved_at", "articles.approved_at ASC", "articles.approved_at DESC", "updated_at", "updated_at ASC", "updated_at DESC", "articles.updated_at", "articles.updated_at ASC", "articles.updated_at DESC"]
  before_save :sanitize_attributes

  define_index do
    set_property :delta => true

    indexes full_text, short_description, title, subtitle, author
    indexes ["LOWER(`articles`.`title`)"], :as => :title_sort, :sortable => true
    indexes state,    :sortable => true

    has feed_id,      :sortable => true
    has updated_at,   :sortable => true
    has approved_at,  :sortable => true
    has date,         :sortable => true
  end
  
 	acts_as_commentable
  acts_as_state_machine :initial => :new
  
  state :new
  state :rejected
  state :approved, 
    :enter => Proc.new { |article|
    article.approved_at = Time.now
    article.save },
    :exit => Proc.new { |article|
    article.approved_at = nil
    article.save }
  state :archived
  
  event :reject do
    transitions :to => :rejected, :from => :new
    transitions :to => :rejected, :from => :approved
  end

  event :approve do
    transitions :to => :approved, :from => :new, :guard => Proc.new { |article| article.approvable? }
    transitions :to => :approved, :from => :rejected, :guard => Proc.new { |article| article.approvable? }
  end
  
  event :archive do
    transitions :to => :archived, :from => :rejected
  end

  def track(args={})
    super(:request => args[:request])
  end

  def to_param
    "#{self.title}".parameterize("#{self.id}")
  end

  class << self
    
    def total_inbox
      count(:conditions => 'state != "approved" and state != "rejected"')
    end

    def total_approved
      count(:conditions => 'state = "approved"')
    end

    def total_rejected
      count(:conditions => 'state = "rejected"')
    end
    
    def comments_join
      "LEFT OUTER JOIN comments on articles.id = comments.commentable_id"
    end
    
    # Returns an array of the most commented articles based on the section.
    ["News","Opinion","Careers","Blog CACM"].each do |section|
      define_method "most_discussed_#{section.downcase.underscorize}_articles" do
        articles = find(:all, :joins => comments_join,  
          :include => :sections,
          :conditions => ["sections.name = (?) and comments.state = (?)", section, "approved"],
          :group => "comments.commentable_id",
          :order => "COUNT(comments.id) DESC",
          :limit => 5)
      end
    end
    
    # Returns the top five articles for a subject based on comments, reject
    # commentless articles
    def most_discussed_articles_for_subject(subject)
      articles =  find(:all, :joins => comments_join,
        :include => :subjects,
        :conditions => ["subjects.name = (?) and comments.state = (?)", subject, "approved"],
        :group => "comments.commentable_id",
        :order => "COUNT(comments.id) DESC",
        :limit => 5)
    end
  
  end


  # "Blog" articles only get displayed on listing pages and in widgets. they do
  # not get displayed as an article page in our template.
  def is_syndicated_blog_post?
    feed.feed_type.name == "Blog"
  end
  
  # "Articles" get displayed on our site as an article page in our template
  def is_displayed_on_site?
    feed.feed_type.name == "Article"
  end

  def is_dl_article?
    is_a? DLArticle
  end

  def is_manual_article?
    is_a? ManualArticle
  end
  
  def has_special_markup?
    [10,9].include?(self.date.month) and self.date.year.eql?(2002)
  end
  
  def approved_comments_count
    Comment.count(:conditions => {:commentable_id => self.id, :state => 'approved'})
  end

  def approved_comments
    Comment.find(:all, :conditions => ["commentable_id = (?) and state = (?)", self.id, "approved"])
  end
  
  # make sure the article's okay to transition to approved state
  def approvable?
    if class_name == "DLArticle"
      # if the article's a dl article, it needs at least one subject or section
      # to be approved-- it has to live somewhere!
      if sections.empty? && subjects.empty?
        errors.add(:sections, "This article must be assigned to at least one subject or section to be approved.")
        return false
      else
        return true
      end
    elsif (is_displayed_on_site? && class_name != "CacmArticle") || is_manual_article?
      # if the article is displayed on the site or is a manual article, it must
      # have at least one section to be approved.
      if sections.empty?
        errors.add(:sections, "This article must be assigned to at least one section to be approved.")
        return false
      else
        return true
      end
    else
      return true
    end
    
  end

  def before_save
    # don't allow an article to be saved if it's already approved but isn't
    # approvable
    if !approvable? && state == 'approved'
      return false
    else
      # else, we can save. but first, let's scrub those short descriptions
      run_clean_short_description
      return true
    end
  end

  
  def keywords
    self.subjects.map(&:keywords).flatten
  end
  
  def full_title
    self.title + ((self.has_attribute?(:subtitle) and self.subtitle and not self.subtitle.blank?) ? ": #{self.subtitle}" : "")
  end

  def meta_tags= values	
    super([values].flatten.join(';'))
  end 

  private
    
  # This walks over a set attributes and sets them to their html_entitiy decoded
  # version.
  def sanitize_attributes
    %w(author title description keyword).each do |field|
      self.send("#{field}=",HTMLEntities.new.decode(self.send(field)))
    end
  end
    
  # run HtmlMaid's image-and-br removing Hpricot script over the short
  # description
  def run_clean_short_description
    self.short_description = HtmlMaid.clean_short_description(self.short_description)
  end

  def append_meta_tags tag
    self.meta_tags += (self.meta_tags.map(&:to_s) + [tag]).join("; ")
    self.save
  end

  def self.load_tags
    Oracle::Article.load_tags
  end
end
