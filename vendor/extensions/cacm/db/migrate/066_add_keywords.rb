class AddKeywords < ActiveRecord::Migration
  def self.up
    create_table :keywords, :force => true do |t|
      t.column :name, :string
    end
    add_index :keywords, :name
  end
  
  def self.down
    remove_index :keywords, :name
    drop_table :keywords
  end
end