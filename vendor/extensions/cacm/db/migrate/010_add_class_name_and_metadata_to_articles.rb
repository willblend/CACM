class AddClassNameAndMetadataToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :class_name, :string
    add_column :articles, :user_comments, :boolean
    add_column :articles, :news_opinion, :boolean
    add_column :articles, :digital_library, :boolean
    add_column :articles, :acm_resource, :boolean
  end

  def self.down
    remove_column :articles, :acm_resource
    remove_column :articles, :digital_library
    remove_column :articles, :news_opinion
    remove_column :articles, :user_comments
    remove_column :articles, :class_name
  end
end
