class AddIndexToContentTypes < ActiveRecord::Migration
  def self.up
    add_index :content_types, :position
  end
  
  def self.down
    remove_index :content_types, :position
  end
end