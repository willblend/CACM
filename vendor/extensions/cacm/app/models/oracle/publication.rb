class Oracle::Publication < Oracle
  set_table_name 'dldata.publications'
  has_many :issues
end