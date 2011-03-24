class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      t.integer :content_provider_id
      t.string :title
      t.string :author
      t.datetime :date
      t.text :short_description
      t.text :full_text
      t.string :uuid
      t.string :link
      t.timestamps
    end
  end

  def self.down
    drop_table :articles
  end
end
