class AddArticleSectionIndex < ActiveRecord::Migration
  def self.up
    add_index :articles_sections, [:section_id, :article_id]
  end
  
  def self.down
    remove_index :articles_sections, [:section_id, :article_id]
  end
end