module FCK
  module AdminUIExtensions
    
    def self.included(base)
      base.alias_method_chain :set_javascripts_and_stylesheets, :fck
    end
    
    def set_javascripts_and_stylesheets_with_fck
      set_javascripts_and_stylesheets_without_fck

      # NOTE: lowpro is inserted here for completeness, but will be included earlier courtesy of other extensions
      @javascripts << 'lowpro'
      @javascripts << '/fckeditor/fckeditor'
      @javascripts << 'admin/radiant_fck'
    end
    
  end
end
