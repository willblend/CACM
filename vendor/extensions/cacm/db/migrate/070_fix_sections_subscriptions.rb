class FixSectionsSubscriptions < ActiveRecord::Migration
  def self.up
    rename_column :sections_subscriptions, :subject_id, :section_id
  end
  
  def self.down
    rename_column :sections_subscriptions, :section_id, :subject_id
  end
end