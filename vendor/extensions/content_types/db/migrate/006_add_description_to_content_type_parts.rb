class AddDescriptionToContentTypeParts < ActiveRecord::Migration
  def self.up
    add_column :content_type_parts, :description, :string
  end
  
  def self.down
    remove_column :content_type_parts, :description
  end
end
