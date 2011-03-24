module Endeca
  class Query
    include Timeout
    attr_reader :results
    attr_writer :num_results, :fields # in case these need to be tweaked per instance

    def initialize
      @query = Com::Endeca::Navigation::ENEQuery.new
      @query.setNavDescriptors(Com::Endeca::Navigation::DimValIdList.new('0'))
      @terms = Com::Endeca::Navigation::ERecSearchList.new
      @num_results = 200
      @fields = []
      @results = Endeca::ResultSet.new
    end

    # Set the search terms. Accepts a String, multiple String args, 
    # or an array of Strings.
    def terms=(*terms)
      # with smaller sample sizes, results are biased towards terms closest to
      # front of the array. sort_by { rand } adds marginal variance.
      terms = terms.sort_by { rand }.join(' ')
      search_term = Com::Endeca::Navigation::ERecSearch.new('Keywords', terms, 'mode matchany+rel nterms')
      @terms.add(search_term)
    end

    # for debugging
    # def terms
    #   @terms.toString
    # end

    # Execute the query, return an array of Endeca::Result objects.
    def query
      return [] if @terms.isEmpty
      @query.setNavERecSearches(@terms)
      @query.setNavNumERecs(@num_results)
      @query.setNavRecordFilter('Owner:ACM')
      
      field_list = Com::Endeca::Navigation::FieldList.new
      fields = @fields | %w(BibID Title PublicationDate MainParentTitle Subtitle)
      fields.each { |field| field_list.addField(field) }
      @query.setSelection(field_list)
      
      engine = Com::Endeca::Navigation::HttpENEConnection.new(CACM::ENDECA_HOST, CACM::ENDECA_PORT)
      results = begin
        timeout(20) do
          engine.query(@query).getNavigation.getERecs
        end
      # Endeca error classes are created dynamically, so we don't have a way to
      # explicitly rescue them. Otherwise, rescue Timeout::Error, ENEConnectionException ...
      rescue Exception => e
        RAILS_DEFAULT_LOGGER.error "ENDECA ERROR: #{e.message}"
        return []
      end

      return [] if results.size.zero?
      
      it = results.listIterator
      while it.hasNext
        props = it.next.getProperties
        field_hash = fields.inject({}) do |hash,field|
          if prop = props.get(field)
            hash[field.underscore] = prop.toString
          end
          hash
        end
        @results << Result.new(field_hash)
      end
      
      @results
    end
  end
end