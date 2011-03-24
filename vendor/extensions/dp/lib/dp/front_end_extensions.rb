module DP

  # adds in lowpro, custom prototype extensions, and dp_customizations
  module FrontEndExtensions
    
    def self.included(base)
      base.alias_method_chain :set_javascripts_and_stylesheets, :prototype
    end
    
    def set_javascripts_and_stylesheets_with_prototype
      set_javascripts_and_stylesheets_without_prototype

      @javascripts.insert(@javascripts.index('effects') + 1, 'lowpro')
      @javascripts << 'prototype_extensions'
      @javascripts << 'admin/dp_customizations'

      @stylesheets << 'admin/dp_customizations'
    end
    
  end
end
