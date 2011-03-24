config.cache_classes = true
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_controller.fragment_cache_store        = TimedFileStore.new(File.join RAILS_ROOT, %w(tmp cache))
ResponseCache.defaults[:perform_caching]             = false
ActionMailer::Base.default_url_options[:host] = "cacm-test.digitalpulp.com"
