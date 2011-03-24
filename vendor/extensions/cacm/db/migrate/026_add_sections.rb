class AddSections < ActiveRecord::Migration
  def self.up
    create_table :sections do |t|
      t.string :name
      t.timestamps
    end
    
    rename_table :categories, :feed_types
    rename_column :feeds, :category_id, :feed_type_id

    create_table :feeds_sections do |t|
      t.integer :feed_id
      t.integer :section_id
    end
    create_table :feeds_topics do |t|
      t.integer :feed_id
      t.integer :topic_id
    end
    
    drop_table :articles_categories
    
    create_table :articles_sections do |t|
      t.integer :article_id
      t.integer :section_id
    end
  end
  
  def self.down
    drop_table :articles_sections

    create_table :articles_categories do |t|
      t.integer :article_id
      t.integer :category_id
      t.timestamps
    end

    drop_table :feeds_topics
    drop_table :feeds_sections
    rename_column :feeds, :feed_type_id, :category_id
    rename_table :feed_types, :categories
    drop_table :sections
  end
end