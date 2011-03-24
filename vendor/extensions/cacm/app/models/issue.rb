class Issue < ActiveRecord::Base
  has_many :articles, :order => :position
  belongs_to :source, :class_name => "Oracle::Issue", :foreign_key => :issue_id
  order_by 'pub_date desc'

  cattr_reader :per_page
  @@per_page = 12
  
  acts_as_state_machine :initial => :new
  state :new
  state :rejected
  state :approved
  
  event :reject do
    transitions :to => :rejected, :from => :new
    transitions :to => :rejected, :from => :approved
  end

  event :approve do
    transitions :to => :approved, :from => :new, :guard => Proc.new {|x| !x.selected_article_ids.blank? }
    transitions :to => :approved, :from => :rejected, :guard => Proc.new {|x| !x.selected_article_ids.blank? }
  end
  
end