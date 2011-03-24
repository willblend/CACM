module CACM
  module WelcomeControllerExtensions
    
    def self.included(base)
      base.class_eval do
        alias_method_chain :logout, :cacm_session
      end
    end
    
    # remove current member when signing out of radiant to prevent any cross-contamination
    # with frontend
    def logout_with_cacm_session
      logout_without_cacm_session
      session[:oracle] = nil
    end
    
  end
end