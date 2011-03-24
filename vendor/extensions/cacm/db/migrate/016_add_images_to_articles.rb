class AddImagesToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :article_image_250_id, :integer
    add_column :articles, :article_image_160_id, :integer
    add_column :articles, :article_image_100_id, :integer
    add_column :articles, :alt_text, :string
  end
  
  def self.down
    remove_column :articles, :alt_text, :string
    remove_column :articles, :article_image_100_id, :integer
    remove_column :articles, :article_image_160_id, :integer
    remove_column :articles, :article_image_250_id, :integer
  end
end