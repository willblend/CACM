class AddPositionToContentTypes < ActiveRecord::Migration
  def self.up
    add_column :content_types, :position, :integer
    ContentType.reset_column_information
    ContentType.find(:all).each do |t|
      t.insert_at(1)
      t.move_to_bottom
    end
  end
  
  def self.down
    remove_column :content_types, :position
  end
end
