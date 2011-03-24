module AssetManager
  module BelongsToAsset
    def self.included(base)
      base.class_eval do
        def self.belongs_to_asset(name, options={})
          fk = options.delete(:foreign_key)
          self.belongs_to name, {:foreign_key => (fk.nil? ? "#{name}_id" : fk ), :class_name => 'Asset'}.merge(options)
          self.alias_attribute "#{name}_id", fk unless fk.nil?
        end
      
      end
    end
  end
end