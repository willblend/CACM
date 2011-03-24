class AddUuidIndexes < ActiveRecord::Migration
  def self.up
    add_index :articles, :uuid
  end

  def self.down
    remove_index :articles, :uuid
  end
end