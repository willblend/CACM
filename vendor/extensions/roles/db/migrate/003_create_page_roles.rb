class CreatePageRoles < ActiveRecord::Migration
  def self.up
    create_table :page_roles, :id => false do |t|
      t.integer :role_id, :page_id
    end
    add_index :page_roles, :role_id
    add_index :page_roles, :page_id
  end

  def self.down
    drop_table :page_roles
  end
end
