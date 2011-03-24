config.cache_classes = true
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_controller.fragment_cache_store        = TimedFileStore.new(File.join RAILS_ROOT, 'cache')
ResponseCache.defaults[:perform_caching]             = true
ENV['LD_LIBRARY_PATH'] = '/opt/local/instantclient_11_1'

ActionMailer::Base.default_url_options[:host] = "cacm.digitalpulp.com"
