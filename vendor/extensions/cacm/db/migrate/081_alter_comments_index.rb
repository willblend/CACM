class AlterCommentsIndex < ActiveRecord::Migration
  def self.up
    remove_index :comments, :name => :commentable_polymorphs
    add_index :comments, [:commentable_type, :commentable_id, :state], :name => "commentable_polymorphs"
  end
  
  def self.down
    remove_index :comments, :name => :commentable_polymorphs
    add_index :comments, [:commentable_id, :commentable_type], :name => "commentable_polymorphs"
  end
end