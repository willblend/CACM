class AddArticleSubtitles < ActiveRecord::Migration
  def self.up
    add_column :articles, :subtitle, :string
  end
  
  def self.down
    remove_column :articles, :subtitle
  end
end