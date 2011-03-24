class AddDeltaToAssets < ActiveRecord::Migration
  def self.up
    add_column :assets, :delta, :boolean
    add_column :assets, :sphinx_deleted, :boolean
  end

  def self.down
    remove_column :assets, :delta
  end
end
