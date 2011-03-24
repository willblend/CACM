class AddOracleIdToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :oracle_id, :integer
  end
  
  def self.down
    remove_column :articles, :oracle_id
  end   
end