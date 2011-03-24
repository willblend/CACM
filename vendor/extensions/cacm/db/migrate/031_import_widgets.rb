class ImportWidgets < ActiveRecord::Migration
  def self.up
    Snippet.find(:all, :conditions => ["name LIKE ?", "widget%"]).each do |snippet|
      Widget.create(:name => snippet.name, :content => snippet.content, :created_by_id => snippet.created_by_id, :updated_by_id => snippet.updated_by_id)
    end
  end

  def self.down
    Widget.find(:all).map(&:destroy)
  end
end