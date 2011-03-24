class DropPrimaryKeyInHabtmJoinTables < ActiveRecord::Migration
  def self.up
    remove_column :articles_topics, :id
    remove_column :articles_categories, :id
  end

  def self.down
  end
end
