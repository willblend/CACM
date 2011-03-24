class AddIndexToArticlesSections < ActiveRecord::Migration
  def self.up
    add_index :articles_sections, [:article_id, :section_id]
  end
  
  def self.down
    remove_index :articles_sections
  end
end