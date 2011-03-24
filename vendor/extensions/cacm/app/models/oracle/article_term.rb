class Oracle::ArticleTerm < Oracle
  set_table_name 'dldata.assigned_ccs'
  set_inheritance_column nil
  belongs_to 'article', :class_name => 'Oracle::Article', :foreign_key => :id
  belongs_to :ccs_term, :class_name => 'Oracle::CCSTerm', :foreign_key => :ccs_node  
end