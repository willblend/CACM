class RenameTopicsToSubjects < ActiveRecord::Migration
  def self.up
    rename_table :topics, :subjects

    rename_column :articles_topics, :topic_id, :subject_id
    rename_table :articles_topics, :articles_subjects

    rename_column :feeds_topics, :topic_id, :subject_id
    rename_table :feeds_topics, :feeds_subjects
  end
  
  def self.down
    rename_table :feeds_subjects, :feeds_topics
    rename_column :feeds_topics, :subject_id, :topic_id
    rename_table :articles_subjects, :articles_topics
    rename_column :articles_topics, :subject_id, :topic_id
    rename_table :subjects, :topics
  end
end