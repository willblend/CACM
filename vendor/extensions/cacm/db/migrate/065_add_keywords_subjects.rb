class AddKeywordsSubjects < ActiveRecord::Migration
  def self.up
    create_table :keywords_subjects, :id => false, :force => true do |t|
      t.column :keyword_id, :int
      t.column :subject_id, :int
    end
    add_index :keywords_subjects, :subject_id
    add_index :keywords_subjects, :keyword_id
  end

  def self.down
    drop_table :keywords_subjects
  end
end
