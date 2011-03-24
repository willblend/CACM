class Section < ActiveRecord::Base
  has_and_belongs_to_many :articles, :conditions => {:state => 'approved'}, :order => "approved_at DESC"
  has_and_belongs_to_many :feeds
    
  acts_as_tree :order => "name"
  acts_as_list

  cattr_reader :per_page
  @@per_page = 10
  
  # return all articles belonging to this section as well as any of this section's children
  def all_articles(pag={})
    pag[:include]     = :sections
    pag[:order]       = 'approved_at DESC'
    pag[:conditions]  = ['articles_sections.section_id IN (?) AND state = (?)', [self.id, *children.map(&:id)], 'approved']
    Article.paginate(pag)
  end
  
  # return all articles belonging to this section as well as any of this section's children from a particular month
  def all_articles_by_year_month(pag={})
    start_date = DateTime.civil(pag.delete(:year), pag.delete(:month)) rescue Time.now.beginning_of_month
    end_date = start_date.end_of_month

    pag[:include]     = :sections
    pag[:order]       = "date DESC"
    pag[:conditions]  = ['articles_sections.section_id IN (?) AND state = (?) AND date BETWEEN (?) and (?)', [self.id, *children.map(&:id)], 'approved', start_date, end_date]

    Article.paginate(pag)
  end

  # returns earliest article in this section and any of its subsections
  def earliest_article
    Article.find(:first, 
                 :include => :sections,
                 :order => "date ASC",
                 :conditions => ['articles_sections.section_id IN (?) AND state = (?)', [self.id, *children.map(&:id)], 'approved'])
  end
  
  # returns earliest article in this section and any of its subsections
   def latest_article
     Article.find(:first, 
                  :include => :sections,
                  :order => "date DESC",
                  :conditions => ['articles_sections.section_id IN (?) AND state = (?)', [self.id, *children.map(&:id)], 'approved'])
   end
  
  def to_param
    if (self.name == 'Opinion')
      # because nothing lives at /opinion
      return 'opinion/articles'
    else
      [self, *ancestors].reverse.map do |section|
        section.name.downcase.gsub(/[^A-Za-z0-9]/, '-').squeeze('-')
      end.join('/')
    end
  end 

  # tag extractor
  
  def title_as_tag
    title.gsub(/[^a-zA-Z0-9_\-\s\/()'.& ]/, '_')
  end 
end