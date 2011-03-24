module DP
  module PageExtensions
    
    def self.included(base)
      base.instance_eval do
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def fetch_page_and_parts(page, parts)
        page = !page.class.name.eql?("Page") ? Page.find(page) : page
        results = PagePart.find(:all, :conditions => ["page_id = ? AND name in (?)", page, parts])
        hash = {}
        results.collect { |r| hash[r.name.intern] = r.content }
        parts.each { |p| hash[p.intern] = hash[p.intern].nil? ? "" : hash[p.intern] }
        hash.merge!(page.attributes.delete_if { |k,v| !["title","slug","breadcrumb"].include?(k) }.symbolize_keys)
        hash[:url] = page.url
        return hash
      end
    end
    
    def full_url
      page = is_draft? ? draft_parent : self
      page.root.site.url(page.url)
    end
    
    def tag_wrapper(tagname, innerhtml = nil, htmloptions = nil)
      if innerhtml.nil?
        "<#{tagname.downcase}#{" " if htmloptions}#{htmloptions.map { |k,v| %(#{k}="#{v}" ) } if htmloptions}/>"
      else
        "<#{tagname.downcase}#{" " if htmloptions}#{htmloptions.map { |k,v| %(#{k}="#{v}" ) } if htmloptions}>#{innerhtml}</#{tagname.downcase}>"
      end
    end
  
    
    # fetch_page_and_parts
    # returns a hash of page attributes and page parts
    # first argument is either a page's id or the page object
    # second argument is a string or array of strings for which page parts you want
    # the hash returned contains title,url,slug,breadcrumb attributes along with the page part's content
    # if the page part isn't found, that part's key has a value of ""
    # example:
    #  = tag.locals.my_page = fetch_page_and_parts(some_page, ["main_body","teaser"])
    # would give you a hash with the folllowing attributes:
    # - tag.locals.my_page[:title]
    # - tag.locals.my_page[:url]
    # - tag.locals.my_page[:slug]
    # - tag.locals.my_page[:breadcrumb]
    # - tag.locals.my_page[:main_body]
    # - tag.locals.my_page[:teaser]
    # these would then be converted to radius tags by iterating over the symbols and returning the value for each key

        
    def fetch_asset(asset)
      return Asset.find(asset) if Asset.exists?(asset)
    end
    
    def image_asset(asset, max_width=9999)
      asset = asset.class.name.eql?("Fixnum") ? Asset.find(asset) : asset
      unless asset.nil?
        width = (max_width < asset.width) ? max_width : asset.width
        return tag_wrapper('img', nil, :src => asset.public_filename, :alt => asset.title, :width => width)
      end
    end

  end
end