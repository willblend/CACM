class IncreaseTextStorage < ActiveRecord::Migration
  def self.up
    # no built-in mediumtext migration. lame! any limit over 64K forces mediumtext column.
    change_column :articles, :full_text, :text, :limit => 65.kilobytes
  end
  
  def self.down
    change_column :articles, :full_text, :text
  end
end