module AssetManager
  module AdminUIExtensions
    
    def self.included(base)
      base.alias_method_chain :set_javascripts_and_stylesheets, :asset_picker
    end
    
    def set_javascripts_and_stylesheets_with_asset_picker
      set_javascripts_and_stylesheets_without_asset_picker

      @javascripts << 'admin/AssetPicker'
    end
    
  end
end
