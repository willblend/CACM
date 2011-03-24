class RemoveMultiSite < ActiveRecord::Migration
  def self.up
    drop_table(:sites) if defined? MultisiteExtension
    remove_column(:pages, :site_id) if Page.columns.detect { |c| c.name == 'site_id' }
  end
  
  def self.down
    if defined? MultisiteExtension
      add_column :pages, :site_id, :integer
      create_table "sites", :force => true do |t|
        t.string  "name"
        t.string  "domain"
        t.integer "homepage_id"
        t.integer "position",    :default => 0
        t.string  "base_domain"
      end
    end
  end
end