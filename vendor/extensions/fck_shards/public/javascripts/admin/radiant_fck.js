// FCK integration with Radiant
var RadiantFCK = Behavior.create({
  initialize: function(){
    // get the parent node so we can contextually remove the IFRAME later
    this.parent_node = this.element.up('div');

    // save the initial arguments for re-creation (enabling) later
    this.editor_arguments = arguments;

    // if FCK exists and we're all clear, then create the FCK instance
    if (!Object.isUndefined(window["FCKeditor"]) && this.constructor.enabled) {
      this.createEditor();
    }
  },

  createEditor: function(){
    var args = $A(this.editor_arguments);

    // arguments are: id, width, height, toolbar_config
    this.editor = new FCKeditor(this.element.id, args[1], args[2], args[3]);

    // use the config name for building the paths to the support files if it exists
    var config_name = (Object.isString(args[0]) && !args[0].blank()) ? args[0] : "default";

    // use the Radiant-specific FCK config file
    this.editor.Config['CustomConfigurationsPath'] = "/fckeditor.customizations/default.config.js"; // always use default config
    // this.editor.Config['CustomConfigurationsPath'] = "/fckeditor.customizations/" + config_name + ".config.js";

    // each instance gets its own CSS and mini-templates
    // this.editor.Config['EditorAreaCSS']    = "/fckeditor.customizations/default.styles.css";
    this.editor.Config['EditorAreaCSS']    = "/fckeditor.customizations/" + config_name + ".styles.css";
    // this.editor.Config['TemplatesXmlPath'] = "/fckeditor.customizations/default.templates.xml";
    this.editor.Config['TemplatesXmlPath'] = "/fckeditor.customizations/" + config_name + ".templates.xml";
    this.editor.Config['StylesXmlPath']    = "/fckeditor.customizations/default.styles.xml";
    // this.editor.Config['StylesXmlPath']    = "/fckeditor.customizations/" + config_name + ".styles.xml";

    // URLs have to be set here, as the radiant_fck_config.js gets loaded in the IFRAME
    for (var url in this.constructor.URLs) {
      this.editor.Config[url] = this.constructor.URLs[url];
    }

    // adjust the page picker root node, if present
    if (!this.constructor.page_picker_root_node.blank()) {
      this.editor.Config['DP_PagePickerURL'] += '?root=' + this.constructor.page_picker_root_node;
    }

    // insert the editor into the document
    this.editor.ReplaceTextarea();

    // store the frame and config DOM nodes for later use
    this.frame_node = $(this.element.id + '___Frame');
    this.config_node = $(this.element.id + '___Config');
  },

  destroyEditor: function(){
    var api = FCKeditorAPI.GetInstance(this.element.id);
    if (!api) { return; }

    // update the original TEXTAREA with the content from the WYSIWYG
    api.UpdateLinkedField();

    // remove all the nodes that FCK created
    this.parent_node.select('iframe').invoke('remove');
    this.frame_node = null;
    this.config_node.remove();
    this.config_node = null;
    this.editor = null;

    // show the original TEXTAREA
    this.element.show();
  }
});


// external interface to enable/disable all FCK instances on the page
RadiantFCK.toggle = function(){ 
  this.instances.invoke( this.enabled ? 'destroyEditor' : 'createEditor');
  this.enabled = !this.enabled;
};


// ---------------------------------------------------------------------------

// enable Radiant integration
RadiantFCK.enabled = true; // evaluated only on onload of the page

// the following are URLs that FCK Editor will interact with, named as they 
// will exist in th FCKConfig object.
RadiantFCK.URLs = {
  'DP_AllAssetsURL'        : '/admin/assets/all.fck',
  'DP_AssetManagerURL'     : '/admin/assets/image.fck',
  'DP_ImagePickerURL'      : '/admin/assets/image.fck',
  'DP_VideoPickerURL'      : '/admin/assets/video.fck',
  'DP_AudioPickerURL'      : '/admin/assets/audio.fck',
  'DP_MultimediaPickerURL' : '/admin/assets/multimedia.fck',
  'DP_PagePickerURL'       : '/admin/picker/page.fck'
};

// this variable holds the id of the parent page of the page being 
// edited/created, allowing the PagePicker to display the tree starting at 
// the node.
RadiantFCK.page_picker_root_node = "";


// ---------------------------------------------------------------------------

// bind the RadiantFCK behavior to certain page elements
Event.addBehavior({
  // use simple defaults
  'TEXTAREA.wysiwyg': RadiantFCK('default', "100%", "400", "Standard")

  // or, customize each instance of the editor based on the class name of the TEXTAREA
  // 'TEXTAREA.some-class-name': RadiantFCK(wysiwyg_config, width, height, toolbar_config),
});
