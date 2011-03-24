class CreateContentTypes < ActiveRecord::Migration
  def self.up
    create_table :content_types do |t|
      t.column :name, :string
      t.column :sublayout, :text
      t.column :layout_id, :integer
    end
    add_index :content_types, :name
    
    add_column :pages, :content_type_id, :integer
  end

  def self.down
    drop_table :content_types
    remove_column :pages, :content_type_id
  end
end
