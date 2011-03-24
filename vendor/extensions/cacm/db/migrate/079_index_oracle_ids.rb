class IndexOracleIds < ActiveRecord::Migration
  def self.up
    add_index :articles, :oracle_id
  end

  def self.down
    remove_index :articles, :oracle_id
  end
end