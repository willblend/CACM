class DropSubjectsSectionsSubscriptions < ActiveRecord::Migration
  def self.up
    remove_index :subjects_subscriptions, :subscription_id
    remove_index :sections_subscriptions, :subscription_id
    drop_table :subjects_subscriptions
    drop_table :sections_subscriptions
  end
  def self.down
    create_table :subjects_subscriptions do |t|
      t.integer :subscription_id
      t.integer :subject_id
    end
    
    create_table :sections_subscriptions do |t|
      t.integer :subscription_id
      t.integer :subject_id
    end
    
    add_index :subjects_subscriptions, :subscription_id
    add_index :sections_subscriptions, :subscription_id
    
  end
end
