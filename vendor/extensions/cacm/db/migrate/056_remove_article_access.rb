class RemoveArticleAccess < ActiveRecord::Migration
  def self.up
    drop_table :article_accesses
  end
  
  def self.down
    create_table :article_accesses do |t|
      t.integer  :dl_article_id
      t.datetime :start_date
      t.datetime  :end_date
      t.string :state
      t.timestamps
    end
  end
end