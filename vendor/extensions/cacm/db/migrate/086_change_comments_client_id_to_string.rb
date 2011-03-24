class ChangeCommentsClientIdToString < ActiveRecord::Migration
  def self.up
    change_column :comments, :client_id, :string
  end

  def self.down
    change_column :comments, :client_id, :integer
  end
end