class Oracle::Inclusion < Oracle
  set_table_name 'dldata.inclusions'
  set_inheritance_column nil

  # convenience method, removes extraneous whitespace
  def link
    inclusion.strip
  end
end