class AddIssueIdIndex < ActiveRecord::Migration
  def self.up
    add_index :articles, :issue_id
  end
  
  def self.down
    remove_index :articles, :issue_id
  end
end