class AddPaperclipColumns < ActiveRecord::Migration
  def self.up
    remove_index :assets, :filename
    remove_index :assets, :description
    remove_index :assets, :content_type
    remove_index :assets, :asset_category_id
    rename_column :assets, :content_type, :file_content_type
    rename_column :assets, :filename, :file_file_name
    rename_column :assets, :size, :file_file_size
    remove_column :assets, :width
    remove_column :assets, :height
    remove_column :assets, :asset_category_id
    add_column :assets, :class_name, :string
    add_column :assets, :title, :string
    add_column :assets, :credit, :string
    add_column :assets, :long_description, :text
    add_column :assets, :uploaded_by_id, :integer
  end

  def self.down
    remove_column :assets, :uploaded_by_id
    remove_column :assets, :long_description
    remove_column :assets, :credit
    remove_column :assets, :title
    remove_column :assets, :class_name
    add_column :assets, :width, :integer
    add_column :assets, :height, :integer
    add_column :assets, :asset_category_id, :integer
    rename_column :assets, :file_file_size, :size
    rename_column :assets, :file_file_name, :filename
    rename_column :assets, :file_content_type
    add_index :assets, :filename
    add_index :assets, :description
    add_index :assets, :content_type
    add_index :assets, :asset_category_id
  end
end
