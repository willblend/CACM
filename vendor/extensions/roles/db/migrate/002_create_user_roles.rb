class CreateUserRoles < ActiveRecord::Migration
  def self.up
    create_table :user_roles, :id => false do |t|
      t.integer :role_id, :user_id
    end
    add_index :user_roles, :role_id
    add_index :user_roles, :user_id
  end

  def self.down
    drop_table :user_roles
  end
end
