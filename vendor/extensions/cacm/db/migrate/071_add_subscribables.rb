class AddSubscribables < ActiveRecord::Migration
  def self.up
    create_table :subscribables_subscriptions do |t|
      t.integer :subscription_id
      t.integer :subscribable_id
      t.string  :subscribable_type
    end
  end
  
  def self.down
    drop_table :subscribables_subscriptions
  end
end