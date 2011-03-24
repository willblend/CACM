module SphinxSearch
  module PageExtensions
   
   def self.included(base)
     base.class_eval do
       define_index do
         set_property :delta => true, :group_concat_max_len => 64.kilobytes
         set_property :field_weights => { 'title' => 10 }
         indexes title, parts.content
         has updated_at, status_id, searchable
         where 'searchable = 1'
       end
     end
   end
    
  end
end