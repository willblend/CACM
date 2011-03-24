class TimedFileStore
  module RadiusTags
    include Radiant::Taggable

    # See ActionController::Caching::Fragments for more info on how these
    # two methods work.
    
    # Acts much like the ActionView::Helpers::CacheHelper#cache method.
    # The +name+ param can be a string, in which case the cache will be written
    # at the top of the global keyspace; it can also be a hash of url_for style
    # pairs which will write the cache to a unique path. Global keys are
    # good for widgets like Featured Book, which displays the same content
    # across the entire site. Unique keys are good for things like Featured
    # Article, which may have several different instances on a single page.
    def cache(name, expiry=nil, &block)
      return block.call unless perform_caching
      unless cache = read_fragment(name, expiry)
        cache = block.call
        write_fragment(name, cache)
      end
      cache
    end

    # r:cache hooks into the +cache+ method and takes similar signatures:
    # 
    # <r:cache name="fragment">content</r:cache>
    # This creates a generic cache at the top of the global keyspace and will
    # be shared with any other <r:cache> with the same +name+ attribute. Any
    # extra attributes are ignored.
    # 
    # <r:cache foo="bar" [blort="batz" ...]>content</r:cache>
    # Creates a key based on the current URL. Useful for caches which should
    # not be shared across page instances.
    #
    # Both forms take an optional `time` param which determines lifespan, in seconds:
    # <r:cache name="global_navigation" time="300"> 5-minute content </r:cache>
    tag 'cache' do |tag|
      raise TagError.new("`cache' tag requires a `name' or other attributes.") if tag.attr.empty?
      params = tag.globals.page.request.parameters
      expiry = tag.attr.delete('time')
      expiry &&= expiry.to_i # only cast if present
      name = tag.attr.include?('name') ? tag.attr['name'] : (tag.attr['slug'] ? "#{tag.attr['slug']}/#{tag.globals.page.slug}" : params.merge(tag.attr).symbolize_keys)
      name['url'] &&= name['url'].join('/') if name.is_a?(Hash)
      cache name, expiry do
         tag.expand
      end
    end

    # r:cache_layout works similarly to r:cache but is designed to be used at 
    # a higher level than fragments. Therefore it does not require a fragment 
    # named or extra attributes and instead uses the request path plus any 
    # explicitly mentioned query parameters to form the cached fragment name
    #
    # If you have additional query parameters that are necessary for content 
    # generation the method body below will need to be edited in the same fashion 
    # as the page = and date = lines below and finally added to the clean_path string
    tag 'cache_layout' do |tag|
      if preview?
        tag.expand
      else
        keys  = request.parameters.symbolize_keys
        url   = keys[:url].is_a?(Array) ? keys[:url].join("/") : keys[:url]
        page  = (keys[:p] && keys[:p] != '1') ? "-page-#{keys[:p]}" : ''
        date  = keys[:month_and_year] || ''

        clean_path = url+page+date
      
        cache clean_path do
          tag.expand
        end
      end
    end

    # Optional reading:
    # Many widgets/snippets could use either the internal (cache do) or external
    # (r:cache) implementation. I opted to draw the line at idempotence-by-URL.
    # Idempotent tags should use the internal implementation; nonidempotent
    # should use the external.

  end
end