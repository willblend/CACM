class IndexCommentablePolymorphs < ActiveRecord::Migration
  def self.up
    add_index :comments, [:commentable_id, :commentable_type], :name => "commentable_polymorphs"
  end

  def self.down
    remove_index :comments, :name => :commentable_polymorphs
  end
end