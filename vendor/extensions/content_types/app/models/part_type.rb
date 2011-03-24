class PartType < ActiveRecord::Base
  has_many :content_type_parts
  
  validates_presence_of :name, :field_type
  validates_inclusion_of :field_type, :allow_nil => true,
                         :in => %w{text_area text_field check_box hidden asset}
end
