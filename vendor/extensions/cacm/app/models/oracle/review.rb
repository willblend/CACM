class Oracle::Review < Oracle
  set_table_name 'dldata.reviews'
  alias_attribute :authors, :review_authors
  alias_attribute :text, :review
end