class Oracle::CCSTerm < Oracle
  set_table_name 'dldata.ccs_lookup'
  set_inheritance_column :nil
  set_primary_key :ccs_node
end