class AddSubjectsArticlesIndex < ActiveRecord::Migration
  def self.up
    add_index :articles_subjects, [:subject_id, :article_id]
  end
  
  def self.down
    remove_index :articles_subjects, [:subject_id, :article_id]
  end
end