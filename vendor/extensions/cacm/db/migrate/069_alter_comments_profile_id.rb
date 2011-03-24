class AlterCommentsProfileId < ActiveRecord::Migration
  def self.up
    rename_column :comments, :profile_id, :client_id
  end

  def self.down
    rename_column :comments, :client_id, :profile_id
  end
end