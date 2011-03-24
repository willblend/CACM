class AddArticleImageAndDropCustomSizes < ActiveRecord::Migration
  def self.up
    remove_column :articles, :article_image_100_id
    remove_column :articles, :article_image_160_id
    remove_column :articles, :article_image_250_id
    remove_column :articles, :alt_text
    add_column  :articles, :article_image_id, :integer
  end
  
  def self.down
    remove_column :articles, :article_image_id
    add_column :articles, :alt_text, :string
    add_column :articles, :article_image_250_id, :integer
    add_column :articles, :article_image_160_id, :integer
    add_column :articles, :article_image_100_id, :integer
  end
end