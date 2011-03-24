# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 21) do

  create_table "account_tokens", :force => true do |t|
    t.string "token"
    t.string "email"
    t.string "client"
  end

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.string   "author"
    t.datetime "date"
    t.text     "short_description"
    t.text     "full_text"
    t.string   "uuid"
    t.string   "link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "feed_id"
    t.string   "state"
    t.string   "class_name"
    t.boolean  "user_comments",                  :default => false
    t.boolean  "news_opinion",                   :default => false
    t.boolean  "digital_library",                :default => false
    t.boolean  "acm_resource",                   :default => false
    t.integer  "image_id"
    t.integer  "delta",             :limit => 4, :default => 1
    t.string   "description"
    t.string   "keyword"
    t.integer  "issue_id"
    t.datetime "approved_at"
    t.integer  "oracle_id"
    t.text     "toc"
    t.integer  "position"
    t.text     "leadin"
    t.integer  "comments_count",                 :default => 0
    t.string   "subtitle"
    t.text     "top_branding"
    t.text     "bottom_branding"
    t.boolean  "featured_article",               :default => false
    t.boolean  "mobile",                         :default => false, :null => false
  end

  add_index "articles", ["uuid"], :name => "index_articles_on_uuid"
  add_index "articles", ["feed_id", "state"], :name => "index_articles_on_feed_id_and_state"
  add_index "articles", ["issue_id"], :name => "index_articles_on_issue_id"
  add_index "articles", ["oracle_id"], :name => "index_articles_on_oracle_id"
  add_index "articles", ["class_name", "uuid"], :name => "index_articles_on_class_name_and_uuid"

  create_table "articles_sections", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "section_id"
  end

  add_index "articles_sections", ["article_id", "section_id"], :name => "index_articles_sections_on_article_id_and_section_id"
  add_index "articles_sections", ["section_id", "article_id"], :name => "index_articles_sections_on_section_id_and_article_id"

  create_table "articles_subjects", :id => false, :force => true do |t|
    t.integer  "article_id"
    t.integer  "subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "articles_subjects", ["subject_id", "article_id"], :name => "index_articles_subjects_on_subject_id_and_article_id"

  create_table "assets", :force => true do |t|
    t.string   "file_content_type"
    t.string   "file_file_name"
    t.integer  "file_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "description",       :limit => 1024
    t.date     "expires_on"
    t.string   "class_name"
    t.string   "title"
    t.string   "credit"
    t.text     "long_description"
    t.integer  "uploaded_by_id"
    t.boolean  "delta"
    t.boolean  "sphinx_deleted"
    t.string   "purpose"
    t.datetime "file_updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.text     "comment"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.string   "client_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state"
  end

  add_index "comments", ["commentable_type"], :name => "index_comments_on_commentable_type"
  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["client_id"], :name => "index_comments_on_profile_id"
  add_index "comments", ["commentable_type", "commentable_id", "state"], :name => "commentable_polymorphs"

  create_table "config", :force => true do |t|
    t.string "key",   :limit => 40, :default => "", :null => false
    t.string "value",               :default => ""
  end

  add_index "config", ["key"], :name => "key", :unique => true

  create_table "content_type_parts", :force => true do |t|
    t.integer "content_type_id"
    t.string  "name"
    t.string  "filter_id"
    t.integer "part_type_id"
    t.string  "description"
  end

  add_index "content_type_parts", ["content_type_id"], :name => "index_content_type_parts_on_content_type_id"

  create_table "content_types", :force => true do |t|
    t.string  "name"
    t.text    "content"
    t.integer "layout_id"
    t.integer "position"
    t.string  "page_class_name"
  end

  add_index "content_types", ["name"], :name => "index_content_types_on_name"
  add_index "content_types", ["position"], :name => "index_content_types_on_position"

  create_table "emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.integer  "last_send_attempt", :default => 0
    t.text     "mail"
    t.datetime "created_on"
  end

  create_table "extension_meta", :force => true do |t|
    t.string  "name"
    t.integer "schema_version", :default => 0
    t.boolean "enabled",        :default => true
  end

  create_table "feed_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "section"
  end

  create_table "feeds", :force => true do |t|
    t.string   "name"
    t.string   "feedurl"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "feed_type_id"
    t.datetime "last_ingest"
    t.boolean  "active",                   :default => true
    t.string   "class_name"
    t.boolean  "news_opinion"
    t.boolean  "digital_library"
    t.boolean  "acm_resource"
    t.boolean  "user_comments"
    t.integer  "default_article_image_id"
  end

  create_table "feeds_sections", :id => false, :force => true do |t|
    t.integer "feed_id"
    t.integer "section_id"
  end

  create_table "feeds_subjects", :id => false, :force => true do |t|
    t.integer "feed_id"
    t.integer "subject_id"
  end

  create_table "hits", :force => true do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.string   "user_ip"
    t.string   "user_agent"
    t.string   "referer"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hits", ["trackable_id"], :name => "index_hits_on_trackable_id"

  create_table "issues", :force => true do |t|
    t.integer  "issue_id"
    t.string   "state"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "selected_article_ids"
    t.datetime "pub_date"
  end

  create_table "keywords", :force => true do |t|
    t.string "name"
  end

  add_index "keywords", ["name"], :name => "index_keywords_on_name"

  create_table "keywords_subjects", :id => false, :force => true do |t|
    t.integer "keyword_id"
    t.integer "subject_id"
  end

  add_index "keywords_subjects", ["subject_id"], :name => "index_keywords_subjects_on_subject_id"
  add_index "keywords_subjects", ["keyword_id"], :name => "index_keywords_subjects_on_keyword_id"

  create_table "layouts", :force => true do |t|
    t.string   "name",          :limit => 100
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "content_type",  :limit => 40
    t.integer  "lock_version",                 :default => 0
  end

  create_table "meta_tags", :force => true do |t|
    t.string "name", :default => "", :null => false
  end

  add_index "meta_tags", ["name"], :name => "index_meta_tags_on_name", :unique => true

  create_table "page_parts", :force => true do |t|
    t.string  "name",      :limit => 100
    t.string  "filter_id", :limit => 25
    t.text    "content"
    t.integer "page_id"
  end

  add_index "page_parts", ["page_id", "name"], :name => "parts_by_page"

  create_table "page_roles", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "page_id"
  end

  add_index "page_roles", ["role_id"], :name => "index_page_roles_on_role_id"
  add_index "page_roles", ["page_id"], :name => "index_page_roles_on_page_id"

  create_table "pages", :force => true do |t|
    t.string   "title"
    t.string   "slug",            :limit => 100
    t.string   "breadcrumb",      :limit => 160
    t.string   "class_name",      :limit => 25
    t.integer  "status_id",                      :default => 1,     :null => false
    t.integer  "parent_id"
    t.integer  "layout_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "published_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "virtual",                        :default => false, :null => false
    t.integer  "lock_version",                   :default => 0
    t.string   "description"
    t.string   "keywords"
    t.integer  "draft_of"
    t.boolean  "searchable",                     :default => true
    t.integer  "delta"
    t.integer  "position"
    t.integer  "content_type_id"
  end

  add_index "pages", ["draft_of"], :name => "index_pages_on_draft_of"
  add_index "pages", ["searchable"], :name => "index_pages_on_searchable"
  add_index "pages", ["class_name"], :name => "pages_class_name"
  add_index "pages", ["parent_id"], :name => "pages_parent_id"
  add_index "pages", ["slug", "parent_id"], :name => "pages_child_slug"
  add_index "pages", ["virtual", "status_id"], :name => "pages_published"

  create_table "part_types", :force => true do |t|
    t.string "name"
    t.string "field_type"
    t.string "field_class"
    t.string "field_styles"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.integer  "position"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "snippets", :force => true do |t|
    t.string   "name",          :limit => 100, :default => "", :null => false
    t.string   "filter_id",     :limit => 25
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.integer  "lock_version",                 :default => 0
  end

  add_index "snippets", ["name"], :name => "name", :unique => true

  create_table "subjects", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscribables_subscriptions", :force => true do |t|
    t.integer "subscription_id"
    t.integer "subscribable_id"
    t.string  "subscribable_type"
  end

  add_index "subscribables_subscriptions", ["subscribable_id", "subscribable_type"], :name => "index_subscribable_polymorphs"
  add_index "subscribables_subscriptions", ["subscription_id"], :name => "index_subscribables_subscriptions_on_subscription_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "client_id"
    t.string   "email"
    t.boolean  "html_emails"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "subscriptions", ["client_id"], :name => "index_subscriptions_on_client_id"

  create_table "taggings", :force => true do |t|
    t.integer "meta_tag_id",                   :null => false
    t.integer "taggable_id",                   :null => false
    t.string  "taggable_type", :default => "", :null => false
  end

  add_index "taggings", ["meta_tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_meta_tag_id_and_taggable_id_and_taggable_type", :unique => true

  create_table "this_day_in_histories", :primary_key => "tdihID", :force => true do |t|
    t.string  "image_1",     :limit => 50
    t.text    "alt_text_1"
    t.text    "caption_1"
    t.string  "tdihMonth",   :limit => 9
    t.integer "tdihDay",     :limit => 2
    t.string  "tdihYear",    :limit => 4
    t.text    "title"
    t.text    "description"
    t.string  "image_2",     :limit => 50
    t.text    "alt_text_2"
    t.text    "caption_2"
    t.string  "image_3",     :limit => 50
    t.text    "alt_text_3"
    t.text    "caption_3"
  end

  create_table "user_roles", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "user_roles", ["role_id"], :name => "index_user_roles_on_role_id"
  add_index "user_roles", ["user_id"], :name => "index_user_roles_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "name",          :limit => 100
    t.string   "email"
    t.string   "login",         :limit => 40,  :default => "", :null => false
    t.string   "password",      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.text     "notes"
    t.integer  "lock_version",                 :default => 0
    t.string   "salt"
    t.string   "session_token"
  end

  add_index "users", ["login"], :name => "login", :unique => true

  create_table "widgets", :force => true do |t|
    t.string   "name"
    t.text     "content"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "notes"
  end

end
