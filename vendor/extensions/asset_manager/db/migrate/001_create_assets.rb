class CreateAssets < ActiveRecord::Migration
  def self.up
    create_table :assets do |t|
      # attachment_fu columns
      t.column :content_type,   :string
      t.column :filename,       :string
      t.column :size,           :integer
      t.column :width,          :integer
      t.column :height,         :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime

      # custom metadata
      t.column :description, :string, :limit => 1024
      t.column :expires_on, :date
      
      # categories
      t.column :asset_category_id, :integer
    end
    add_index :assets, :asset_category_id
  end

  def self.down
    drop_table :assets
  end
end
