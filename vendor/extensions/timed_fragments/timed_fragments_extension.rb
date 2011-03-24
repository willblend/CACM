class TimedFragmentsExtension < Radiant::Extension
  version "0.1"
  description "Timed fragment caching and Radius tag integration"
  
  FRAGMENT_LIFETIME = 60.minutes
  
  def activate
    ActionView::Helpers::CacheHelper.class_eval do
      include TimedFileStore::Helpers::CacheHelper
    end
    Page.class_eval do
      include ActionController::Caching::Fragments
      include TimedFileStore::RadiusTags
      cattr_accessor :perform_caching
    end
    Page.fragment_cache_store = TimedFileStore.new(File.join(RAILS_ROOT, %w(tmp cache)))
    
    # FIXME: find a better spot to declare Page.perform_caching.
    # congif.after_initialize is too soon, other places are not obvious.
    Page.perform_caching = %w(development_cached cache staging production).include?(RAILS_ENV)
  end
  
  def deactivate
  end
  
end