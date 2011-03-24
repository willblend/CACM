class CacmController < ApplicationController

  no_login_required
  radiant_layout "standard_fragment_cached"
  filter_parameter_logging :passw # filter passwd, password, &c.
  include CACM::DLSession
  include CACM::SectionsPathHelper
  self.allow_forgery_protection = false # authenticity tokens render caching useless
  
end