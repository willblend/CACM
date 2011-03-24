class CreateIssues < ActiveRecord::Migration
  def self.up
    create_table :issues do |t|
      t.integer :issue_id
      t.string :state
      t.timestamps
    end
  end

  def self.down
    drop_table :issues
  end
end
