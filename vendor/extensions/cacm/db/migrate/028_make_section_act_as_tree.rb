class MakeSectionActAsTree < ActiveRecord::Migration
  def self.up
    add_column :sections, :parent_id, :integer
  end
  
  def self.down
    remove_column :sections, :parent_id
  end
end