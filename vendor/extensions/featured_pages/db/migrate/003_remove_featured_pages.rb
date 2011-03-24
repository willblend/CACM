class RemoveFeaturedPages < ActiveRecord::Migration
  def self.up
    remove_column :pages, :featured_page
  end

  def self.down
    add_column :pages, :featured_page, :boolean, :default => false
    Page.reset_column_information
    Page.update_all(['featured_page = ?',false])
  end
end
