module DP
  module RadiusExtensions

    def self.included(base)
      base.class_eval do
        include ActionController::UrlWriter
      end
      class << base
        def default_url_options
          {:controller => "site", :action => "show_page", :only_path => true}
        end
      end
    end

  end
end