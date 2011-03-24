class AddCommentCounter < ActiveRecord::Migration
  def self.up
    ThinkingSphinx.deltas_enabled = false
    add_column :articles, :comments_count, :integer, :default => 0
    # populate counts; only select articles that already have comments
    Article.find(:all, :include => :comments, :group => :commentable_id, :conditions => 'comments.id IS NOT NULL').each do |article|
      article.update_attribute(:comments_count, article.comments.size)
    end
  end
  
  def self.down
    remove_column :articles, :comments_count
  end
end