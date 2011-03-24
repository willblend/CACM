class AddSubscribablesIndex < ActiveRecord::Migration
  def self.up
    add_index :subscribables_subscriptions, [:subscribable_id, :subscribable_type], :name => "index_subscribable_polymorphs"
    add_index :subscribables_subscriptions, :subscription_id
  end
  
  def self.down
    remove_index :subscribables_subscriptions, :subscription_id
    remove_index :subscribables_subscriptions, :name => :index_subscribable_polymorphs
  end
end