module CACM
  module WillPaginateForRadiant

    # NEEDS_DOC: marking the lines that differ from stock will_paginate would be optimal here.
    
    # Will Pagiante For Radiant
    # ________________________
    
    # INFO: 
    # Slight adaptation of the will_pagination view helper to play nicely with radiant
    #  
    
    # USAGE:
    # parameters....
    # the parameters hash that is passed in should contain both the URL (which is a radiant default param)
    # and any get params that you would like to be kept
    
    # EXAMPLE:
    #   
    # collected_params = tag.globals.page.request.parameters.reject { |key, value| key == "action" || key == "controller" || value == ""}
    #    ^this grabs the params for sending to the method to render the links 
    # will_paginate_radiant(my_collection_o_foos, collected_params)
    
    # NOTES:
    # Integration points have been spec'ed but the rest of the functionality is tested within the will_paginate specs

    module Paginator
      def will_paginate_radiant(collection = nil, parameters={})  
        # Make sure something was at least passed in
        unless collection
          raise ArgumentError, "You Need To Pass Me Something To Render Links For"
        end
        
        # If the collection only has one page then do not show pagination
        return nil unless WillPaginateForRadiant::Paginator.total_pages_for_collection(collection) > 1

        # Set parameters for passage
        # relative_root = parameters.delete('url') ... spec hack.
        relative_root = url rescue "/"
        get_vars = parameters
        if parameters
          # Make query string!
          get_vars = Paginator.query_stringify(get_vars)
        else
          get_vars = ""
        end  
          
        
        
        # Make a new link maker!
        renderer = WillPaginateForRadiant::LinkerRenderer.new
        renderer.prepare(collection, relative_root, get_vars)
        renderer.to_html  
      end
      
      class << self
        def total_pages_for_collection(collection)
          collection.total_pages  
        end
      
        def query_stringify(parameters)
          query = ""
          parameters.each_pair do |key, value|
            unless key == "" || key == nil || value == nil || value == ""
              query << "&#{key}=#{value}"
            end 
          end
          query
        end
      end
    end

    class LinkerRenderer  
      attr_accessor :gap_marker

      def gap_marker
        '<span class="gap">&hellip;</span>'
      end

      def prepare(collection,relative_root,get_vars)
        @collection = collection
        @relative_root = relative_root
        @get_vars = get_vars
      end

      def to_html
        links = windowed_links
        links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', '&laquo; Prev')
        links.push    page_link_or_span(@collection.next_page,     'disabled next_page', 'Next &raquo;')
        links.join(' ')
      end

      protected  
        def visible_page_numbers
          
          # We need less numbers displaying in our listings -  let's reject any
          # pagination numbers that aren't the first (1), last (total_number)
          # or the current_page or 2 away from the current page.
          
          # Ex. current_page = 9 out of 202
          
          # potentials = 1, 7,         8,         9,       10,         11,        202
          #              1, current-2, current-1, current, current +1, current+2, total_pages
          
          # then we take (1..total_pages).to_a as ALL potential pages for this
          # paginated listing, and we remove anything that isn't in our
          # porentials array defined above. this avoids having to remove negative
          # numbers, or non-existenent links, etc etc.
          
          potentials = [1,total_pages,current_page,current_page-1,current_page+1,current_page-2,current_page+2]
          potentials.delete_if { |x| x < 1 || x > total_pages }
          
          return (1..total_pages).to_a.delete_if { |x| !potentials.include?(x) }
          
          # Back to paginating business as usual. -amlw 1/8/08
          
        end

        def windowed_links
          prev = nil

          visible_page_numbers.inject [] do |links, n|
            # detect gaps, if there is a huge space between record numbers show it with dots.
            links << gap_marker if prev and n > prev + 1
            links << page_link_or_span(n, 'current')
            prev = n
            links
          end
        end

        def page_link_or_span(page, span_class, text = nil)
          text ||= page.to_s

          if page and page != current_page
            classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
            page_link page, text, :class => classnames
          else
            page_span page, text, :class => span_class
          end
        end

        # The 'page' param has been changed to avoid a conflict with preview, first to 'current_page' (r425) and now to 'p' (ticket #476) - bak 2/10/09
        def page_link(page, text, attributes = {})
          # ?p=1 is implied on the first page of a collection, so don't draw ?p=1 to avoid duplicate cache / search results
          if page == 1
            if @get_vars.empty?
              "<a href='#{@relative_root}'>#{text}</a>"
            else
              "<a href='#{@relative_root}?#{@get_vars}'>#{text}</a>"
            end
          else
            "<a href='#{@relative_root}?p=#{page}#{@get_vars}'>#{text}</a>"
          end
        end

        def page_span(page, text, attributes = {})
          if attributes[:class]
            "<span class='#{attributes[:class]}'>#{text}</span>"
          else
            "<span>#{text}</span>"
          end
        end
        
      
      private

      
        def previous_page
          @collection.previous_page
        end

        def current_page
          @collection.current_page
        end

        def total_pages
          @total_pages ||= WillPaginateForRadiant::Paginator.total_pages_for_collection(@collection)
        end

        def rel_value(page)
          case page
          when @collection.previous_page; 'prev' + (page == 1 ? ' start' : '')
          when @collection.next_page; 'next'
          when 1; 'start'
          end
        end
    end
  end
end