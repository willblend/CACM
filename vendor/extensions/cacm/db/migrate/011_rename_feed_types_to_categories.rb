class RenameFeedTypesToCategories < ActiveRecord::Migration
  def self.up
    rename_table :feed_types, :categories
    rename_column :feeds, :feed_type_id, :category_id
  end

  def self.down
    rename_column :feeds, :category_id, :feed_type_id
    rename_table :categories, :feed_types
  end
end
