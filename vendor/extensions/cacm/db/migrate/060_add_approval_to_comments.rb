class AddApprovalToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :state, :string
  end
  
  def self.down
    remove_column :comments, :state
  end
end