# This modifies an earlier table i created to fake out web accounts until we had the procedures
# Now I'm using the same table to temporarily store the token, email, and membership info for 
# users wishing to creating a new web account - KS 01/13/09

class TemporaryProfiles < ActiveRecord::Migration
  def self.up
    add_column :profiles, :token, :string
    add_column :profiles, :email, :string
    add_column :profiles, :client, :string
    remove_column :profiles, :location
    remove_column :profiles, :name
  end

  def self.down
    add_column :profiles, :name, :string
    add_column :profiles, :location, :string
    remove_column :profiles, :client
    remove_column :profiles, :token
    remove_column :profiles, :email
  end
end