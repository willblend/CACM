module LOCAL_CONFIG
  def self.included(base)
    constants.each { |c| base.const_set c, const_get(c) }
  end

  # CONSTANTS SET HERE WILL OVERRIDE THOSE ADDED TO MODULE CACM

  # Local Settings
  # DOMAIN = /^https?\:\/\/cacm\.local\:\d+\//

  # Staging Settings
  # DOMAIN = /^https?\:\/\/cacm\.digitalpulp\.com\//

  # Production Settings
  # DOMAIN = /^https?\:\/\/(beta\.)?cacm\.acm\.org\//
  # ENDECA_HOST = '192.168.1.61'
end

ActionMailer::Base.perform_deliveries = false