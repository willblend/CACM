class AddDraftsFields < ActiveRecord::Migration
  def self.up
    add_column :pages, :draft_of, :integer
    add_index :pages, :draft_of
  end
  
  def self.down
    remove_index :pages, :draft_of
    remove_column :pages, :draft_of
  end
end
