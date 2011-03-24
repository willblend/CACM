class DropToc < ActiveRecord::Migration
  def self.up
    remove_column :subscriptions, :toc
  end
  
  def self.down
    add_column :subscriptions, :toc, :text 
  end
end