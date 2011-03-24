class AddNotesToWidgets < ActiveRecord::Migration
  def self.up
    add_column :widgets, :notes, :text
  end
  
  def self.down
    remove_column :widgets, :notes
  end
end