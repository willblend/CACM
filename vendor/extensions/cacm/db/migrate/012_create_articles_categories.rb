class CreateArticlesCategories < ActiveRecord::Migration
  def self.up
    create_table :articles_categories do |t|
      t.integer :article_id
      t.integer :category_id
      t.timestamps
    end
  end

  def self.down
    drop_table :articles_categories
  end
end
