class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table  :subscriptions do |t|
      t.integer   :client_id
      t.string    :email
      t.boolean   :toc
      t.boolean   :html_emails
      t.timestamps
    end

    create_table :subjects_subscriptions do |t|
      t.integer :subscription_id
      t.integer :subject_id
    end
    
    create_table :sections_subscriptions do |t|
      t.integer :subscription_id
      t.integer :subject_id
    end
    
    add_index :subscriptions, :client_id
    add_index :subjects_subscriptions, :subscription_id
    add_index :sections_subscriptions, :subscription_id
    
  end

  def self.down
    remove_index :subjects_subscriptions, :subscription_id
    remove_index :sections_subscriptions, :subscription_id
    remove_index :subscriptions, :client_id
    drop_table :subscriptions
    drop_table :subjects_subscriptions
    drop_table :sections_subscriptions
  end
end
