class Subject < ActiveRecord::Base
  has_and_belongs_to_many :articles, :conditions => {:state => 'approved'}, :order => "approved_at DESC"
  has_and_belongs_to_many :feeds
  has_and_belongs_to_many :keywords, :uniq => true do
    # normalize on downcase and ensure uniqueness when setting
    def <<(kw)
      kw.downcase!
      self.concat Keyword.find_or_create_by_name(kw) unless proxy_target.map(&:name).include?(kw)
    end
    
    # double quote delimited list of keywords
    def to_s
      map { |term| %Q("#{term.name}") }.join(' ')
    end
  end

  cattr_reader :per_page
  @@per_page = 10

  def to_param
    self.name.gsub(/\W/, '-').squeeze('-')
  end

end