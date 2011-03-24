class CreateContentTypeParts < ActiveRecord::Migration
  def self.up
    create_table :content_type_parts do |t|
      t.column :content_type_id, :integer
      t.column :name, :string
      t.column :filter_id, :string
    end
    
    add_index :content_type_parts, :content_type_id
  end

  def self.down
    drop_table :content_type_parts
  end
end
