class Oracle < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "oracle_#{RAILS_ENV}"
end