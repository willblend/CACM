class SearchController < CacmController
  radiant_layout "standard_fragment_cached"

  def search
    # redirect to the homepage if there is no search term present
    if params[:q].blank?
      redirect_to "/" and return
    end

    # URL for ACM's production GSA
    gsa_url = "http://gsa1.acm.org/search?"

    # NOTE: the ACM GSA is running v4.6.4 of the system software, so you need 
    # to reference the following URL for all integration info:
    #   http://code.google.com/apis/searchappliance/documentation/46/

    # the gsa's query string represented as a hash. the absolute minimum 
    # required for our search to function correctly.
    # 
    # additional information on all query parameters is at:
    #   http://code.google.com/apis/searchappliance/documentation/46/xml_reference.html
    gsa_config = {
      "client"          => "cacmdp_frontend",  # the front-end to use
      "output"          => "xml_no_dtd",       # use XSLT (instead of the GSA XML)
      "proxystylesheet" => "cacmdp_frontend",  # use the XSLT for our front-end
      "site"            => "cacm_collection",  # the collection to search
      "ie"              => "UTF-8",            # input encoding
      "oe"              => "UTF-8",            # output encoding
      "getfields"       => "author.date"       # META tags to show in search results
    }

    # removing any attempt to access the cached page
    params[:q] = params[:q].gsub(/cache:\S*/, '').strip.squeeze(" ")

    # catch a blank query param after filtering for cache params
    if params[:q].blank?
      redirect_to "/" and return
    end

    # the user's query
    gsa_config["q"] = params[:q]
    
    # query expansion
    gsa_config["entqr"] = "0"

    # these are only used after the first page, or when sorting
    gsa_config["start"] = params[:start] if params[:start] # pagination
    
    # sorting; unescaped due to the later encoding
    if params[:sort]
      gsa_config["sort"]  = URI.unescape(params[:sort])
    else
      gsa_config["sort"] = "date:D:S:d1" # sort by date by default
    end

    # allow removing of filter to "show all results"
    gsa_config["filter"] = params[:filter] if params[:filter]

    # used to limit the search to a certain directory ("more results from...")
    gsa_config["as_sitesearch"] = params[:as_sitesearch]  if params[:as_sitesearch]

    # tells the GSA to not cache the XSLT, for debugging/development purposes
    gsa_config["proxyreload"] = "1" unless (RAILS_ENV == "production")

    # fetch the results via HTTP
    logger.info("GSA URL: " + URI.encode(gsa_url) + gsa_config.to_query) unless (RAILS_ENV == "production")
    @search = Net::HTTP.get(URI.parse(URI.encode(gsa_url) + gsa_config.to_query))
  end

end