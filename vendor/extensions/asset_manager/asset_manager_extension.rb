require_dependency 'application'

class AssetManagerExtension < Radiant::Extension
  version "0.11"
  description "A full-featured asset manager"
  url "http://code.digitalpulp.com"
  
  # REST makes ugly URLs sometimes, here's the longhand version:
  define_routes do |map|
    map.with_options :controller => 'assets', :defaults => { :format => :html } do |assets|
      assets.with_options :conditions => { :method => :get } do |a|
        a.recent_assets       '/admin/assets/recent/:format',         :action => 'recent'
        a.browse_assets       '/admin/assets/browse/:type.:format',   :action => 'browse'
        a.expiring_assets     '/admin/assets/report.:format',         :action => 'report'
        a.new_asset           '/admin/assets/:type/new.:format',      :action => 'new'
        a.edit_asset          '/admin/assets/:type/:id/edit.:format', :action => 'edit'
        a.assets              '/admin/assets/:type.:format',          :action => 'recent'
      end
      assets.asset   '/admin/assets/:type.:format',     :action => 'update',  :conditions => { :method => :put }
      assets.connect '/admin/assets/:type.:format',     :action => 'create',  :conditions => { :method => :post }
      assets.connect '/admin/assets/:type.:format',     :action => 'destroy', :conditions => { :method => :delete }
    end

    map.with_options :controller => 'assets' do |plain|
      plain.connect '/admin/assets', :action => 'recent'
    end
  end
  
  def activate
    raise "DigitalPulp :: Please install the acts_as_modified plugin"   unless defined? ActiveRecord::Acts::Modified
    raise "DigitalPulp :: Please install the paperclip plugin"          unless defined? ActiveRecord::Base::Paperclip

    # required for unzipping zip archives
    require 'zip/zipfilesystem'

    # required for SWFUpload
    require 'asset_manager/cgi_session'

    # subclasses of assets
    Dir.glob(File.join(AssetManagerExtension.root, %w(app models), '*_asset.rb')).each { |f| require_dependency f }

    ActiveRecord::Base.send               :include, AssetManager::BelongsToAsset
    ActionView::Helpers::FormBuilder.send :include, AssetManager::FormBuilderExtensions

    # add in then necessary JS to allow asset picking
    ApplicationController.send            :include, AssetManager::AdminUIExtensions

    admin.tabs.add "Assets", "/admin/assets", :before => 'CMS Settings'

    Paperclip.options[:image_magick_path] = '/opt/local/bin'

    # asset filename customization
    # NOTE: the style passed in can apparently be either :style or '' (blank)
    interpolations = Paperclip::Attachment.interpolations
    interpolations[:style]        = lambda { |attachment, style| (style.to_s == 'original' || style.to_s == "") ? "" : "." + style.to_s }
    interpolations[:id_partition] = lambda { |attachment, style| ("%08d" % attachment.instance.id).scan(/\d{4}/).join("/") }
    interpolations[:cache_buster] = lambda { |attachment, style| '?' + File.mtime(attachment.path).to_i.to_s rescue '' }

    # mime type aliases; used to describe different Asset Manager contexts (clever use of formats)
    Mime::Type.register_alias 'text/html', :fck # FCK context
    Mime::Type.register_alias 'text/html', :rad # Radiant context
  end
  
  def deactivate
  end
  
end
