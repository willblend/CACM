class ManualFeed < Feed
  # handle manually entered content here
  # remember to create articles of class ManualArticle

  def display_name
    "(Manual)"
  end

  def self.all_feeds
    find(:all, :order => 'name ASC').map { |f| [f.name, f.id] }
  end

end