class Oracle::Section < Oracle
  set_table_name 'dldata.sections'
  set_inheritance_column nil
  belongs_to :issue
  has_many :articles, :class_name => 'Oracle::Article'

  def title_as_tag
    title.gsub(/[^a-zA-Z0-9_\-\s\/()'.& ]/, '_')
  end 
end