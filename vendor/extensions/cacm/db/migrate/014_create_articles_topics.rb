class CreateArticlesTopics < ActiveRecord::Migration
  def self.up
    create_table :articles_topics do |t|
      t.integer :article_id
      t.integer :topic_id
      t.timestamps
    end
  end

  def self.down
    drop_table :articles_topics
  end
end
