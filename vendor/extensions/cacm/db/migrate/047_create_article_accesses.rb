class CreateArticleAccesses < ActiveRecord::Migration
  def self.up
    create_table :article_accesses do |t|
      t.integer  :dl_article_id
      t.datetime :start_date
      t.datetime  :end_date
      t.timestamps
    end
  end

  def self.down
    drop_table :article_accesses
  end
end
