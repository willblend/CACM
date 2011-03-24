ActiveRecord::Schema.define(:version => 0) do
  
  create_table "resources", :force => true do |t|
    t.column "name",       :string
    t.column "city",       :string
    t.column "state",      :string
    t.column "zip",        :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end
  
  create_table "assets", :force => true do |t|
    t.column "resource_id",:integer
    t.column "name",       :string
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end
  
  create_table "hits", :force => true do |t|
    t.column "pro_user_id", :integer
    t.column "trackable_id", :integer
    t.column "trackable_type", :string
    t.column "user_ip", :string
    t.column "user_agent", :string
    t.column "referer", :string
    t.column "created_at", :datetime
  end
  
  create_table "randos", :force => true do |t|
    t.column "name",       :string
  end
  
end