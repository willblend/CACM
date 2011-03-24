class CreateFakeProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.string :name
      t.string :location
    end
  end

  def self.down
    drop_table :profiles
  end
end