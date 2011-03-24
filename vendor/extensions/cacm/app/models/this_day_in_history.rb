class ThisDayInHistory < ActiveRecord::Base
  # This class is populated by a mysql dump of the TDIH content that was provided to us.
  # The declaration is here so it can be queried like an AR class for the TDIH widget to work.
  # To repopulate the this_day_in_histories table, see this_day_in_history.rake.
end