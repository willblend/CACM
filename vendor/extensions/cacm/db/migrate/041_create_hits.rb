class CreateHits < ActiveRecord::Migration
  def self.up
    create_table :hits, :force => true do |t|
      t.integer :trackable_id
      t.string :trackable_type
      t.string :user_ip
      t.string :user_agent
      t.string :referer
      t.timestamps
    end
  end
  
  def self.down
    drop_table :hits
  end
end