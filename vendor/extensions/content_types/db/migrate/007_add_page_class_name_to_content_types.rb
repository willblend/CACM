class AddPageClassNameToContentTypes < ActiveRecord::Migration
  def self.up
    add_column :content_types, :page_class_name, :string, :default => nil
  end
  
  def self.down
    remove_column :content_types, :page_class_name
  end
end