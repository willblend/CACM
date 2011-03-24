class AddMultisiteSupportToSearch < ActiveRecord::Migration
  def self.up
    remove_column :pages, :delta
    add_column :pages, :delta, :integer
    add_column :pages, :site_id, :integer
    Page.reset_column_information
    Page.find(:all).each do |page|
      # update directly, bypass any active delta indexing
      ActiveRecord::Base.connection.execute "UPDATE pages SET site_id = #{page.root.site.id} WHERE id = #{page.id}"
    end
  end

  def self.down
    remove_column :pages, :delta
    add_column :pages, :delta, :boolean, :default => false
    remove_column :pages, :site_id
  end
end