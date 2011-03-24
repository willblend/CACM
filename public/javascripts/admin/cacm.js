// back-end JS file for CACM
// ---------------------------------------------------------------------------

// Radiant FCK
// ---------------------------------------------------------------------------
if (window['RadiantFCK']) {
  Event.addBehavior({
    "TEXTAREA.wysiwyg-article-standard"       : RadiantFCK("article",        "640", "500", "Standard"), // 555 width column
    "TEXTAREA.wysiwyg-article-standard-small" : RadiantFCK("article",        "640", "250", "Standard"), // same as above, shorter editing window
    "TEXTAREA.wysiwyg-article-inline"         : RadiantFCK("article-inline", "640", "180", "Inline"),   // 555 width column; inline variant
    "TEXTAREA.wysiwyg-article-narrow"         : RadiantFCK("narrow",         "640", "500", "Standard"), // 485 width column; image feature mini template
    "TEXTAREA.wysiwyg-article-branding"       : RadiantFCK("article-branding", "640", "150", "Branding"), // 555 width column, short, restricted tools
    "TEXTAREA.wysiwyg-widget"                 : RadiantFCK("widget",        "100%", "350", "Standard")
  });
}

// Association Pickers
// ---------------------------------------------------------------------------
if (window['AssociationPicker']) {
	Event.addBehavior({
		
		// Associated Widgets
		"INPUT.associated-widgets-field" : MultipleAssociationPicker({
			
			associated_items : "widgets",
			associations_href : "/admin/picker/associated_widgets",
			table_cols_length : '3',
			table_cols_markup : '<col width="25%" /><col width="55%" /><col width="20%" />',
			
			isAValidFormSubmission : function(){
				this.invalids = [];
				this.table.select('.associated-value').each(function(internal_value){
					var fieldset = internal_value.next('fieldset');
					if (fieldset) {
						if (internal_value.value.empty()) {
							this.invalids.push(internal_value);
							var warning = new Element('p', { 'class' : 'PickerWarning' }).update("You must select a featured article or remove this widget.");
							fieldset.insert({ after : warning });
							fieldset.up('.PickerTable').scrollTo();
						}	else {
							var warning = fieldset.next('.PickerWarning');
							if (warning) { warning.remove(); }
						}
					}
				}, this);
				return (this.invalids.size() == 0) ? true : false;
			},
			
			addAssociation : function(response){
				if (this.isAValidAssociation(response['id'])) {
					this.removePlaceholder();
					var row = new Element('tr', { 'id' : this.CONFIG['row_prefix'] + response['id'] });
					var title = new Element('td').update(response['title'] + "<input class='value' type='hidden' value='" + response['id'] + "' />");
					if (response['inner_content']) {
						var fields = new Element('td', { 'class' : 'InlineAssociations' }).update(response['inner_content']);
						var input = fields.down('input');
						if (input) {
							AssociationPicker.attach(input, { associated_items : "article", associations_href : "/admin/picker/associated_articles" });
							input.observe('input:updated', this.updateAssociationData.bindAsEventListener(this));
						}
					} else {
						var fields = new Element('td').update();
					}
					var controls = new Element('td', { 'class' : this.CONFIG["controls_class"] }).update(this.CONFIG['controls_markup']);
					row.insert({ top : title }).insert({ bottom : fields }).insert({ bottom : controls });
					this.tbody.insert({ bottom : row });
					this.updateAssociationData();
					this.initializeControls(row);
				} else {
					alert("This association has already been made!");
				}
			}
			
		}),
		
		// Associated Articles
		"INPUT.associated-articles-field" : AssociationPicker({
			associated_items : "article",
			associations_href : "/admin/picker/associated_articles"
		})
		
	});
}

// CAE Admin Interface Behavior
// ---------------------------------------------------------------------------
var CAEFieldToggler = Behavior.create({
  initialize : function(){
    this.month_select = $('month_filter');
    this.year_select = $('year_filter');
    this.tabs = $('cae-tabs');
    if (!this.month_select || !this.year_select || !this.tabs) { return; }
    this.toggleDateFields(this.year_select.selectedIndex);
    this.year_select.observe('change', this.fieldChangeHandler.bindAsEventListener(this));
  },
  fieldChangeHandler : function(){
    this.toggleDateFields(this.year_select.selectedIndex);
  },
  toggleDateFields : function(selected_year_index){
    if (selected_year_index == 0 || selected_year_index == 1) {
			// year select has title option (0), blank option (1)...
      this.month_select.disable();
      this.month_select.selectedIndex = 0;
    } else {
      this.month_select.enable();
    }
  }
});

Event.addBehavior({
  '#feeds_filter_form' : CAEFieldToggler
});

// CAE Article Full Text Editing
// ---------------------------------------------------------------------------

var EditFullTextTrigger = Behavior.create({
  initialize : function(field_type){
    this.wrapper = this.element.up(".field");
    this.field_type = field_type;
    if (!this.wrapper || !this.field_type || !window["RadiantFCK"]) { return; }
    this.article_preview = this.wrapper.down(".ArticlePreview");
    this.debug_html = this.wrapper.down(".DebugHTML");
    if (this.article_preview && this.debug_html) {
      this.article_markup = this.article_preview.innerHTML; // stash markup
      this.element.show().observe('click', this.editFullTextClickHandler.bindAsEventListener(this));
    }
  },
  editFullTextClickHandler : function(){
    this.createFCKEditor();
  },
  createFCKEditor : function(){
    var fck_editor = new Element("textarea", { name : "article[full_text]", id : "article-full-text-wyswiyg-field" });
    this.wrapper.insert({ top : fck_editor });
    fck_editor[Prototype.Browser.Gecko ? "innerHTML" : "value"] = this.article_markup; // non-FF browsers don't like <textarea>innerHTML=
    RadiantFCK.attach(fck_editor, this.field_type, "640", "400", "Standard");
    [this.article_preview,this.debug_html,this.element].invoke('hide');
    this.wrapper.scrollTo();
  }
});