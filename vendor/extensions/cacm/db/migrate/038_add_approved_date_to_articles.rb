class AddApprovedDateToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :approved_at, :datetime
    Article.reset_column_information
    Article.find(:all, :conditions => ["state = ?", 'approved']).each do |a|
      a.approved_at = a.updated_at
      a.save
    end
  end
  
  def self.down
    remove_column :articles, :approved_at
  end
end