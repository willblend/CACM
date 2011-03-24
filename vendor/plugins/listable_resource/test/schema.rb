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
  
end