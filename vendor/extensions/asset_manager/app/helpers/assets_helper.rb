module AssetsHelper
  
  def expiration_date(asset)
    asset.expires_on.blank? ? "Does not expire" : asset.expires_on.to_s(:mdy_time)
  end

  def remove_cachebuster(url)
    url.gsub(/\?.*$/, '')
  end
  
  def just_created
    yield if params[:just_created]
  end
  
  def dimensions(asset)
    "#{asset.width} x #{asset.height}"
  end
  
  def asset_class(asset)
    case
      when asset.video?
        "asset-video"
      when asset.audio?
        "asset-audio"
      when asset.flash?
        "asset-flash"
      when asset.image?
        "asset-image"
      when asset.pdf?
        "asset-pdf"
      when asset.doc?
        "asset-doc"
      when asset.ppt?
        "asset-ppt"
      when asset.xls?
        "asset-xls"
      else
        "asset-generic"
    end
  end

  def asset_icon(asset)
    case
      when asset.video?
        "/images/admin/icon.file.video.l.gif"
      when asset.audio?
        "/images/admin/icon.file.audio.l.gif"
      when asset.flash?
        "/images/admin/icon.file.flash.l.gif"
      when asset.image?
        "/images/admin/icon.file.image.l.gif"
      when asset.pdf?
        "/images/admin/icon.file.pdf.l.gif"
      when asset.doc?
        "/images/admin/icon.file.doc.l.gif"
      when asset.ppt?
        "/images/admin/icon.file.ppt.l.gif"
      when asset.xls?
        "/images/admin/icon.file.xls.l.gif"
      else
        "/images/admin/icon.file.generic.l.gif"
    end
  end

  def asset_expire_class(asset)
    if asset.expired?
      "expired"
    elsif asset.expiring_soon?
      "expiring-soon"
    end
  end


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
