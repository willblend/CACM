class RenameProfiles < ActiveRecord::Migration
  def self.up
    rename_table :profiles, :account_tokens
  end
  
  def self.down
    rename_table :account_tokens, :profiles
  end
end