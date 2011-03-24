class RenameArticleImageId < ActiveRecord::Migration
  def self.up
    rename_column :articles, :article_image_id, :image_id
  end
  
  def self.down
    rename_column :articles, :image_id, :article_image_id
  end
end