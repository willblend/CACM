class SetUtf8OnTables < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.connection.tables.each do |table|
      execute "ALTER TABLE #{table} DEFAULT CHARSET=utf8"
    end
  end

  def self.down
    # Don't even think about trying it
  end
end