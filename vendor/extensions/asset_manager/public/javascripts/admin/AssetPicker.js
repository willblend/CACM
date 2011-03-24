var AssetPicker = Behavior.create(PageWidget, {
	initialize : function(config) {

    this.setOptions(config);

		if (this.element.type == "text") {
			try {
				this.element.type = "hidden";
			} catch(e) { this.element.hide(); }
		}

		this.asset_manager_window = null; // window reference
		this.asset_prefix = this.element.name.gsub(/\[/, "_").gsub(/_id\]/, "").gsub(/\]/, "");

		this.nodes = { };

		this.nodes['filename'] = $(this.asset_prefix + "_filename");

    var parent = this.element.up();

		if (!this.nodes['filename']) {
			this.nodes['filename'] = $(parent.insertBefore(this.createAssetFilenameNode(), this.element));
		}

		if (!$F(this.element).blank()) {
			this.nodes['remove_link'] = $(parent.insertBefore(this.createRemoveAssetLink(), this.nodes['filename'].next()));
		}

		this.nodes['add_link'] = $(parent.insertBefore(this.createPickAssetLink(), this.nodes['filename'].next()));

		this.nodes['asset_preview'] = $(this.asset_prefix + "_asset_preview");

		if (!this.nodes['asset_preview']) {
			this.nodes['asset_preview'] = $(parent.appendChild(this.createAssetPreviewNode()));
			this.nodes['asset_preview'].hide();
		} else {
			this.updateAssetTextField(this.fixAssetURL(this.nodes['asset_preview'].src));
		}
	},

  fixAssetURL : function(url) {
    // FIXME: this could use some refactoring
    return url.split("/").last().split("?").first();
  },

	createAssetFilenameNode : function() {
		return new Element('input', { 'id' : this.asset_prefix + "_filename", 'class' : 'TextInput asset-manager-filename', 'disabled' : 'disabled' });
	},

	createAssetPreviewNode : function() {
    return new Element('img', { 'id' : this.asset_prefix + "_asset_preview", 'class' : 'asset-manager-preview' });
	},

	createRemoveAssetLink : function(input) {
    // FIXME: better 'remove' language for remove button text
    var node = new Element('span', { 'id' : this.element.id + '_remove', 'class' : 'Link remove-asset-link' }).update('Remove');
		node.observe('click', this.removeAssetClickHandler.bindAsEventListener(this));
		return node;
	},
	
	removeAssetClickHandler : function(e) {
		this.removeAsset();
	},
	
	removeAsset : function(e) {
    // FIXME: better 'remove' language for prompt
		if (!confirm("Are you sure want to remove this asset?")) { return; }

		this.nodes['asset_preview'].hide();
		this.nodes['filename'].value = '';
		this.nodes['remove_link'].hide();
		this.element.value = "";
	},
	
	createPickAssetLink : function(input) {
		var node = new Element('span', { 'id' : this.element.id + '_pick', 'class' : 'Link asset-manager-link' }).update("Pick " + this.CONFIG['asset_class']);
		node.observe('click', this.pickAssetClickHandler.bindAsEventListener(this));
		return node;
	},
	
	pickAssetClickHandler : function(e) {
		this.openAssetManagerWindow();
	},

	openAssetManagerWindow : function() {
		if (!this.asset_manager_window || this.asset_manager_window.closed) {
			window['CurrentPicker'] = this;
      // FIXME: randomize window name
			this.asset_manager_window = window.open(this.CONFIG['asset_manager_url'], this.CONFIG['window_name_prefix'] + this.asset_prefix, this.CONFIG['window_options']);
		}
		this.asset_manager_window.focus();
	},

	setAssetInfo : function(asset) {
		window['CurrentPicker'] = null;

		this.element.value = asset.id;

    var filename = this.fixAssetURL(asset.url);

		this.updateAssetTextField(filename);

		if (filename.match('.mp3') == null && filename.match('.flv') == null) { // don't preview mp3's!
			this.nodes['asset_preview'].src = asset.url;
			this.nodes['asset_preview'].show();
		}

		if (!this.nodes['remove_link']) {
			this.nodes['remove_link'] = $(this.element.parentNode.insertBefore(this.createRemoveAssetLink(), this.nodes['add_link'].next()));
		} else {
			this.nodes['remove_link'].show();
		}
	},
	
	updateAssetTextField : function(filename){
		this.nodes['filename'].value = filename;
	}
});

AssetPicker.CONFIG = {
  'asset_manager_url'  : '/admin/assets/all.rad',
  'window_options'     : 'width=960,height=500,toolbars=no,scrollbars=yes', // same as FCK editor context
  'window_name_prefix' : 'AssetManager_',
  'asset_class'        : 'Asset'
};

Event.addBehavior({
	'INPUT.asset-manager-field'       : AssetPicker,
	'INPUT.asset-manager-field-image' : AssetPicker({ 'asset_manager_url' : '/admin/assets/image.rad', 'asset_class' : 'Image' }),
	'INPUT.asset-manager-field-flash' : AssetPicker({ 'asset_manager_url' : '/admin/assets/flash.rad', 'asset_class' : 'Flash File' }),
	'INPUT.asset-manager-field-pdf'   : AssetPicker({ 'asset_manager_url' : '/admin/assets/pdf.rad',   'asset_class' : 'PDF File' }),
  'INPUT.asset-manager-field-audio' : AssetPicker({ 'asset_manager_url' : '/admin/assets/audio.rad', 'asset_class' : 'Audio File' }),
	'INPUT.asset-manager-field-video' : AssetPicker({ 'asset_manager_url' : '/admin/assets/video.rad', 'asset_class' : 'Video File' })
});
