module DpApplicationHelper

  ### navigation helpers

  # Replacement for link_to_if wraps non-links in a span tag with the id and class intact.
  def link_or_span_for(expression, name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
    if expression
      if block_given?
        block.arity <= 1 ? yield(content_tag('span', name)) : yield(content_tag('span', name), options, html_options, *parameters_for_method_reference)
      else
        content_tag('span', name)
      end
    else
      link_to(name, options, html_options, *parameters_for_method_reference)
    end  
  end

  # A or SPAN, depending on whether or not the link URL is the current page
  def link_or_span_for_current(name, options = {}, html_options = {}, &block)
    link_or_span_for current_page?(options), name, options, html_options, &block
  end

  # an LI with 'Selected' class if link URL is current page, plus link_or_span_for_current
  def navigation_list_item(name, options = {}, html_options = {}, &block)
    content_tag :li, link_or_span_for_current(name, options, html_options, &block), :class => (current_page?(options) ? 'Selected' : '')
  end

end
