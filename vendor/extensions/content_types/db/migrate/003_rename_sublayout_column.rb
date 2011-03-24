class RenameSublayoutColumn < ActiveRecord::Migration
  def self.up
    rename_column :content_types, :sublayout, :content
  end
  
  def self.down
    rename_column :content_types, :content, :sublayout
  end
end
