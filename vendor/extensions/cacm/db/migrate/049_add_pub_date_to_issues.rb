class AddPubDateToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :pub_date, :datetime
  end
  
  def self.down
    remove_column :issues, :pub_date
  end   
end