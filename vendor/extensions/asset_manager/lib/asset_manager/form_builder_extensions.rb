module AssetManager
  module FormBuilderExtensions
    def asset_field(method, options = {})
      returning '' do |html|
        html << @template.send(:text_field, @object_name, method, {:class => 'asset-manager-field'}.merge(options).merge(:object => @object))

        if (asset = @object.send(method.to_s.gsub(/_id$/, ''))) && (src = asset.public_filename)
          html << @template.send(:tag, :img, { :src => src, :class => 'asset-manager-preview', 
                                               :alt => '', :id => "#{@object_name.to_s}_#{method.to_s.gsub(/_id$/, '')}_asset_preview" })
        end
      end
    end
  end
end