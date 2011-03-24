# DP Stock Radius Tags
module DP
  module RadiusTags
    include Radiant::Taggable
    class TagError < StandardTags::TagError; end
    
    desc %{
      = Flash =
      Outputs the current flash message or error directly as a string. 
      The type attribute should be a string with a value of "notice", "error",
      or "warning".
    }
    tag "flash" do |tag|
      raise TagError.new("`flash` tag must include a `type` attribute!") unless tag.attr['type']
      request.session["flash"][tag.attr['type'].to_sym]
    end
    
    desc %{
      = Encode =
      Encode a value from the local page object for direct output, using an
      alias of URI.escape, which escapes unsafe characters.
    }
    tag 'encode' do |tag|
      raise TagError.new("`encode` tag must include a `pattr` atrribute representing an accessor on the page model!") unless tag.attr['pattr']
      URI.encode(tag.locals.page[tag.attr['pattr']])
    end
    
    desc %{
      = Standard Navigation =
      Basic navigation functionality. This should probably be copied and 
      pasted into the main project extension so that it can be customized, and
      the portion of HTML below will be put into a snippet that will be 
      customized for the specific nav markup, e.g. r:cacm_navigation
      
      How does this work?
      The entire navigation construct is wrapped into the 
      r:standard_navigation tag. The "levels" attribute is how many levels 
      down the nav will expand to. The "toplevel" attribute determines where 
      the navigation tree will begin- by default, this value is 1 (meaning 
      that the top-level "sections" will be the homepage's children), but this
      can be changed to scope the navigation to within a certain section. This
      wrapping tag will open the navigation and start the tree at the desired
      location.
      
      The render_level tag contains the business logic of the navigation: it
      determines which pages should be displayed and which section of the
      navigation to markup to use for each node. 
      
      The next_level tag moves the page scope down in the tree and is used to
      limit the number of trees that the navigation will expand. If the levels
      attribute is exceeded, it won't expand. These should wrap render_levels
      in the expanded portions of your navigation markup.
      
      The navigation markup sections are:
        Here: displayed when the nav node is the current page. Expands.
        Normal: displayed for regular links, not selected/expanded
        Selected: displayed when the node is active in the page tree. Expands.
        Selected Childless: displayed when the node is active but can't expand
      
      Snippet Example:
      <pre><code><r:standard_navigation levels="4"><ul id="standard-navigation">
        <r:here><li><strong><r:escape_html:title /></strong>
        <r:next_level><ul>
        <r:render_level />
        </ul></r:next_level>
        </li></r:here>
        <r:selected><li><a href="<r:url />"><r:escape_html:title /></a>
        <r:next_level><ul>
        <r:render_level />
        </ul></r:next_level>
        </li></r:selected>
        <r:selected_childless><li><strong><r:escape_html:title /></strong></li></r:selected_childless>
        <r:normal><li><a href="<r:url />"><r:escape_html:title /></a></li></r:normal>
        </ul></r:standard_navigation></code></pre>
    }
    tag 'standard_navigation' do |tag|
      tag.locals.level = 1
      tag.locals.levels = (tag.attr['levels'] || 2).to_i
      top_level = (tag.attr['toplevel'] || 1).to_i * -1
      hash = tag.locals.section_nav = {}
      tag.expand
      tag.locals.current_uri = tag.globals.page.url.chomp("/")
      tag.locals.section = tag.globals.page.ancestors[top_level] || tag.globals.page
      tag.locals.page = tag.locals.section
      return tag.render('render_level') unless tag.locals.section.children.empty?
    end
    tag 'standard_navigation:render_level' do |tag|
      returning [] do |result|
        tag.locals.page.children.each do |child|
          hash = tag.locals.section_nav
          tag.locals.page = child
          child_uri = child.url.chomp("/")
          child_children = child.children
          if child.class_name.eql? "RailsPage"
            if tag.locals.current_uri.include? child_uri
              result << hash[:selected_childless].call
            else
              result << hash[:normal].call
            end
          else
            if tag.locals.current_uri.include? child_uri
              if tag.locals.current_uri.eql? child_uri
                result << hash[:here].call
              else
                if child_children.empty?
                  result << hash[:selected_childless].call
                else
                  result << hash[:selected].call
                end
              end
            else
              result << hash[:normal].call
            end
          end
        end
      end.join("\n")
    end
    tag 'standard_navigation:next_level' do |tag|
      unless tag.locals.page.children.empty?
        if tag.locals.level < tag.locals.levels
          tag.locals.level += 1
          tag.expand
        end
      end
    end
    [:here,:normal,:selected,:selected_childless].each do |type|
      tag "standard_navigation:#{type}" do |tag|
        hash = tag.locals.section_nav
        hash[type] = tag.block
      end
    end
    
    desc %{
      Conditional Logic Tags. All of the following tags are defining two tags:
      the "if_xxx" and the "unless_xxx" versions of the same statement.
      
      if_current_page : Is the currently scoped page also the current page?
      if_current_path : Is this the current URL path?
        - attr["path"], should be exact relative path
      if_has_content : Is this part active and populated on the scoped page?
        - attr["part"], should be the name of the content type part
      if_booolean_part : Is this boolean page part true on the scoped page?
        - attr["part"], should be name of the boolean page part
      if_at_depth : Is the scoped page at this exact depth from the root?
        - attr["level"], should be integer for page tree depth
      if_before_depth : Is the scoped page less than this depth from the root?
        - attr["level"], should be integer for page tree depth
      if_past_depth : Is the scoped page greater than this depth from the root?
        - attr["level"], should be integer for page tree depth
      if_descendent_of : Is the scoped page a descendent of this page?
        - attr["slug"], should be slug of page to test descendency of
      if_site : Is this the scoped page's Site?
        - attr["name"], should be the site's name
      if_layout : Is this the scoped page's Layout?
        - attr["name"], should be the layout's name
      if_content_type : Is this the scoped page's Content Type?
        - attr["name"], should be the content type's name
      if_rails_page : Is the scoped page a RailsPage?
      if_flash : Is there a flash message of this type?
        - attr["type"], should be the flash type: warning|error|notice
      if_post : Is there a POST on this page?
      if_params : Is this paramter on this page? Optionally does it equal this?
        - attr["name"], required, should be name of GET value
        - attr["equals"], optional, should be value to test GET name for
      if_env : Is the current environment this, or one of these?
        - attr["types"], string or array of strings: development|test|production
    }
    [:if,:unless].each do |condition|
      class_eval <<-END
        
        tag "#{condition}_current_page" do |tag|
          tag.expand #{condition} tag.globals.page.eql?(tag.locals.page)
        end
        
        tag "#{condition}_current_url" do |tag|
          raise TagError.new("`#{condition}_current_path` tag must include a `url` attribute!") unless tag.attr['url']
          tag.expand #{condition} tag.globals.page.url.chomp('/').eql?(tag.attr['url'].chomp('/'))
        end
        
        tag "#{condition}_has_content" do |tag|
          raise TagError.new("`#{condition}_has_content` tag must include a `part` tag, a string for the part name!") unless tag.attr['part']
          part = PagePart.find_by_name_and_id(tag.attr['part'], tag.locals.page.id)
          tag.expand #{condition} !tag.locals.page.part(tag_part_name(tag)).nil? || !tag.locals.page.part(tag_part_name(tag)).content.empty?
        end
        
        tag "#{condition}_boolean_part" do |tag|
          raise TagError.new("`#{condition}_boolean_part` tag must include a `part` attribute, the name of the boolean part!") unless tag.attr['part']
          bool = PagePart.find_by_name_and_page_id(tag.attr['part'], tag.locals.page)
          bool_content = bool ? bool.content : false
          tag.expand #{condition} bool_content
        end
        
        tag "#{condition}_at_depth" do |tag|
          raise TagError.new("`#{condition}_at_depth` tag must include a `level` attribute, how many levels from root!") unless tag.attr['level']
          tag.expand #{condition} tag.locals.page.ancestors.length.eql?(tag.attr['level'].to_i)
        end
        
        tag "#{condition}_before_depth" do |tag|
          raise TagError.new("`#{condition}_before_depth` tag must include a `level` attribute, how many levels from root!") unless tag.attr['level']
          tag.expand #{condition} tag.locals.page.ancestors.length < tag.attr['level'].to_i
        end
        
        tag "#{condition}_past_depth" do |tag|
          raise TagError.new("`#{condition}_past_depth` tag must include a `level` attribute, how many levels from root!") unless tag.attr['level']
          tag.expand #{condition} tag.locals.page.ancestors.length > tag.attr['level'].to_i
        end
        
        tag "#{condition}_descendent_of" do |tag|
          raise TagError.new("`#{condition}_descendent_of` tag must include a `slug` attribute!") unless tag.attr['slug']
          tag.expand #{condition} tag.locals.page.ancestors.collect { |p| p.slug.eql?(tag.attr['slug']) }.include?(true)
        end
        
        tag "#{condition}_path_includes" do |tag|
          raise TagError.new("`#{condition}_path_includes` tag must include a `slug` attribute!") unless tag.attr['slug']
          tag.expand #{condition} request.request_uri.include?(tag.attr['slug'])
        end
        
        tag "#{condition}_site" do |tag|
          raise TagError.new("`#{condition}_site` tag must include a `name` attribute, the name of the site!") unless tag.attr['name']
          class_name = defined?(globals) ? globals.page.class_name : self.class_name
          unless class_name.eql?('RailsPage')
            tag.expand #{condition} Site.find(tag.locals.page.site_id).name.eql?(tag.attr['name'])
          else
            if current_page=Page.find_by_url(request.path.split('/')[0..-2].join('/'))
              tag.expand #{condition} Site.find(current_page.site_id).name.eql?(tag.attr['name'])
            end
          end
        end
        
        tag "#{condition}_layout" do |tag|
          raise TagError.new("`#{condition}_layout` tag must include a `name` attribute, the name of the layout!") unless tag.attr['name']
          layout = tag.locals.page.layout ? tag.locals.page.layout.name : 'this_page_doesnt_have_a_layout_so_evaluate_to_false'
          tag.expand #{condition} layout.eql?(tag.attr['name'])
        end
        
        tag "#{condition}_content_type" do |tag|
          raise TagError.new("`#{condition}_content_type` tag must include a `name` attribute, the name of the content type!") unless tag.attr['name']
          content_type = tag.locals.page.content_type ? tag.locals.page.content_type.name : 'this_page_doesnt_have_a_content_type_so_evaluate_to_false'
          tag.expand #{condition} content_type.eql?(tag.attr['name'])
        end
        
        tag "#{condition}_rails_page" do |tag|
          class_name = defined?(globals) ? globals.page.class_name : self.class_name
          tag.expand #{condition} class_name.eql?('RailsPage')
        end
        
        tag "#{condition}_flash" do |tag|
          raise TagError.new("`#{condition}_flash` tag must include a `type` attribute!") unless tag.attr['type']
          tag.expand #{condition} request.session['flash'] && request.session['flash'][tag.attr['type'].to_sym]
        end
        
        tag "#{condition}_post" do |tag|
          tag.expand #{condition} request.post?
        end
        
        tag "#{condition}_params" do |tag|
          raise TagError.new("`#{condition}_params` tag must include a `name` attribute, the string for the param's key! (`equals` is an optional attr)") unless tag.attr['name']
          if tag.attr['equals']
            if tag.globals.page.request.parameters[tag.attr['name']]
              tag.expand #{condition} tag.globals.page.request.parameters[tag.attr['name']].eql?(tag.attr['equals'])
            end
          else
            tag.expand #{condition} tag.globals.page.request.parameters[tag.attr['name']]
          end
        end
        
        tag "#{condition}_env" do |tag|
          raise TagError.new("`#{condition}_env` tag requires a `types` attribute, either a string or an array!") unless tag.attr['types']
          tag.expand #{condition} tag.attr['types'].split(',').include?(RAILS_ENV)
        end
        
      END
      
    end
  end
end