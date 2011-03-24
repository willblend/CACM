class AddStateToArticleAccess < ActiveRecord::Migration
  def self.up
    add_column :article_accesses, :state, :string
  end

  def self.down
    remove_column :article_accesses, :state
  end
end