class SubscribablesSubscription < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :subscribable, :polymorphic => true
end