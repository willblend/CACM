class AddStateToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :state, :string
  end

  def self.down
    remove_column :articles, :state
  end
end
