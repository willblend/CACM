module CACM
  module ApplicationExtensions
    
    def self.included(base)
      base.class_eval do
        include SslRequirement
        include InstanceMethods
        alias_method_chain :set_javascripts_and_stylesheets, :cacm_customizations
      end
    end
    
    # CACM front-end customizations for Radiant admin interface
    def set_javascripts_and_stylesheets_with_cacm_customizations
      set_javascripts_and_stylesheets_without_cacm_customizations
      @stylesheets << 'admin/cacm'
      @javascripts << 'admin/AssociationPicker'
      @javascripts << 'admin/cacm'
    end
    
    module InstanceMethods
      protected
        def ssl_required?
          super unless %w(test development development_cached).include?(RAILS_ENV)
        end
    end

  end
end