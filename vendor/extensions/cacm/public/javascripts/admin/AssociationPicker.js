var AssociationPicker = Behavior.create(PageWidget, {
	
	initialize: function(config) {
		
		// this.node always needs to be an input[type=text]
		this.node = this.element;
		if (this.node.tagName.toLowerCase() != "input") { return; }
		this.setOptions(config);
		
		// These functions can be overriden in the CONFIG, but if they aren't
		// defined in CONFIG, they will take the default functions.
		this.addAssociation = this.CONFIG['addAssociation'] ? this.CONFIG['addAssociation'] : this.addAssociation;
		this.createPickerInterface = this.CONFIG['createPickerInterface'] ? this.CONFIG['createPickerInterface'] : this.createPickerInterface;
		this.isAValidFormSubmission = this.CONFIG['isAValidFormSubmission'] ? this.CONFIG['isAValidFormSubmission'] : this.isAValidFormSubmission;
		if (typeof(this.addAssociation) != "function" || typeof(this.isAValidFormSubmission) != "function" || typeof(this.createPickerInterface) != "function") { return; }
		
		// Prepare the field update callback. This is called in a few places for
		// various updates of the field value. We need to have this.updateCallback
		// defined as a usable function for later.
		// Usage: this.updateCallback(this) ... passes in this for scope in config
		// Note: These won't be run until this.initialized is true (at end of init)
		if (typeof this.CONFIG["update_callback"] == "function") {
			this.updateCallback = this.CONFIG["update_callback"];
		} else {
			// Just in case the CONFIG went horribly, horribly wrong...
			this.updateCallback = function(scope) { };
		}
		
		// This location is the URL to hit with the previous value of this.node.
		// this URL must be prepared to respond to both XHR requests, which should
		// be able to return the associations based on the params[:data].
		// the URL must also be a picking interface, as it will be hit when the
		// user clicks "Pick XXX" and launches the picking popup. Also, 
		// build out the extra param to send with the picker window (if it exists)
		if (!this.CONFIG['picker_popup_param'].empty()) {
			this.associations_href = this.CONFIG['associations_href'] + "?" + this.CONFIG['picker_popup_param'] + "=" + this.CONFIG['picker_popup_value'];
		} else {
			this.associations_href = this.CONFIG['associations_href'];
		}
		
		// The "meat" of the initialization. 
		this.fetchCurrentAssociations();
		this.createPickerInterface();
		this.initializePicking();
		
		// Sometimes pickers don't have access to the form, since they are
		// being instantiated by another picker and don't actually live in the DOM
		// yet. In this case, we will trust that the original picker will handle
		// validating the form's submit.
		this.form_element = this.node.up('form');
		if (this.form_element) {
			this.form_element.observe('submit', this.formSubmitHandler.bindAsEventListener(this));
		}
		
		// Fire off the initialize callback from the CONFIG. Passes in (this) as
		// only argument to give scope in the CONFIG.
		if (typeof this.CONFIG["initialize_callback"] == "function") {
			this.CONFIG["initialize_callback"](this);
		}
		
		// Set this.initialized to true so update callbacks will fire from now on.
		this.initialized = true;
	},
	
	fetchCurrentAssociations : function(){
		new Ajax.Request(this.associations_href, {
			asynchronous : false,
			method : 'get',
			evalJSON : 'force',
			parameters : { 'data' : this.node.value },
			onSuccess : this.fetchCurrentAssociationsSuccessHandler.bind(this),
			onFailure : this.fetchCurrentAssociationsFailureHandler.bind(this)
		});
	},
	
	fetchCurrentAssociationsSuccessHandler : function(transport){
		// The associations controller should be responding with an ARRAY of 
		// results (each result being a JSON object), with .to_json called
		// before packaging it up. Defaults to [ ] if things get weird.
		this.associations = transport.responseJSON ? transport.responseJSON.evalJSON() : [];
	},
	
	fetchCurrentAssociationsFailureHandler : function(transport){
		// If the AJAX request fails we're in a tricky situation because another
		// picker might be depending on the value of this picker for it's final
		// node value. This way we just display a big warning to hopefully
		// convince the user that hitting Save is a bad idea.
		this.associations = [];
		var wrapper = this.node.up(this.CONFIG['fieldset_class_selector']);
		if (wrapper) { wrapper.insert({ after : this.CONFIG["ajax_failure"]}); }
	},
	
	createPickerInterface : function(){
		
		if (this.associations == null) {
			// This is what happens when we tried to pull a nonexistant association.
			// If the AssociationClass.find(value) returned a NoRecordException,
			// we rescue it with nil and pass null back to the AssociationPicker.
			// This way we can wipe out bad values and not worry about returning 500
			// or re-saving bad data.
			this.node.value = "";
			var display_value = "";
		} else {
			// To account for multiple association pickers, the controllers need
			// to return the associated objects in an array. Since this is a single
			// picker we (should) only be getting one result in response, but let's
			// double-check what's up with this.associations[0] anyways, since our
			// field might have been originally blank.
			if (this.associations[0]) {
				var display_value = this.associations[0]['title'] ?  this.associations[0]['title'] : "";
			} else {
				this.node.value = "";
				var display_value = "";
			}
		}
		
		// Create the fieldset, the visible disabled input which will display the
		// currently associated item, and insert it into the DOM after this.node.
		this.fieldset = new Element('fieldset', { 'class' : 'PickerInterface' });
		this.association_input = new Element('input', { 'type' : 'text', 'value' : display_value, 'class' : 'AssociationInput', 'disabled' : 'disabled' });
		this.association_preview = new Element('div', { 'class' : 'AssociationPreview' });
		this.fieldset.insert({ top : this.association_input }).insert({ top : this.association_preview });
		this.node.insert({ after : this.fieldset });
		this.node.hide();
	},
	
	initializePicking : function(){
		// Create the add and remove buttons, hide the remove button if there is
		// no current association, meaning that this.node would have no value.
		this.button = new Element('a', { 'class' : 'PickerLink', 'href' : this.associations_href }).update('Pick ' + this.CONFIG["associated_items"].capitalize());
		this.node.up().childElements().last().insert({ bottom : this.button });
		this.button.observe('click', this.launchAssociationPickerWindow.bindAsEventListener(this));
		this.remove_button = new Element('a', { 'class' : 'PickerLink RemoveLink', 'href' : this.associations_href }).update('Remove ' + this.CONFIG["associated_items"].capitalize());
		this.button.insert({ after : this.remove_button });
		this.remove_button.observe('click', this.clearPickedAssociation.bindAsEventListener(this));
		if (this.node.value.empty()) { this.remove_button.hide();	}
	},
	
	launchAssociationPickerWindow : function(e){
		e.stop();
		if (!this.picker_window || this.picker_window.closed) {
			
			// Avoid pickers that overwrite each other by making the name somewhat
			// unique. Articles would be referenced as current_articles_picker.
			window['current_' + this.CONFIG['associated_items'].toLowerCase() + '_picker'] = this;
			// But keep this in for "backwards compatability"
			// TODO: Eliminate!
			CurrentPicker = this;
			this.picker_window = window.open(this.associations_href, "AssociationPicker_" + this.node.identify().camelize(), "width=1000,height=600,toolbars=no,scrollbars=yes");
			
		}
		this.picker_window.focus();
	},
			
	isAValidFormSubmission : function(){
		return true;
	},
	
	sendAssociationPopupHandler : function(data){
		this.addAssociation(data);
	},
	
	// This is the most basic association handling. Put the title in the front-
	// displaying input, call updatePickedAssociation() to stash the id
	// into this.node.
	addAssociation : function(response){
		this.association_input.value = response['title'];
		this.updatePickedAssociation(response['id']);
	},
	
	updatePickedAssociation : function(value){
		this.node.value = value;
		this.node.fire('input:updated');
		this.remove_button.setStyle({ display : 'inline' });
		if (this.initialized) {
			this.updateCallback(this);
		}
	},
	
	clearPickedAssociation : function(e){
		e.stop();
		this.node.value = '';
		this.node.fire('input:updated');
		this.association_input.value = '';
		this.association_preview.update();
		this.remove_button.hide();
		if (this.initialized) {
			this.updateCallback(this);
		}
	},
	
	isAValidAssociation : function(id){
		this.valid = true;
		if (this.CONFIG["requires_unique_associations"]) {
			this.node.value.split(",").each(function(current_id){
				if (current_id == id) { this.valid = false; }
			}, this);
		}
		return this.valid;
	},
	
	formSubmitHandler : function(e){
		if (!this.isAValidFormSubmission()){
			e.stop();
		}
	}
});

AssociationPicker.CONFIG = {
	
	associated_items : "widgets",
	associations_href : '/admin/widget_picker',
	
	// Callbacks: one happens after all other initialization, the other anytime
	// this.node input has it's value updated and "input:updated" is fired.
	// Note that these callbacks each take (this) as an argument, so that you
	// can use scope within the CONFIG'd functions.
	initialize_callback : function(scope) { },
	update_callback : function(scope) { },
	
	// When popping the picker window, add an additional param to the associations
	// href. This won't be used when fetching the currently associated items --
	// we're assuming that the additional param being sent during the association
	// picking was sufficient to filter for whatever validation it needed before
	// the associations were actually made. If it's blank nothing will be sent.
	picker_popup_param : "",
	// This could be something like this.node.value or just a hardcoded value.
	// Don't include the ? or = (e.g. url?param=value)... those characters
	// are inserted by the script.
	picker_popup_value : "",
	
	fieldset_class_selector : ".content-type-part",
	ajax_failure : "<p><strong class=\"error\">An error occurred while retrieving the current association. Saving this page may result in corrupted data. Proceed with caution!!</strong></p>"
};

var MultipleAssociationPicker = Behavior.create(AssociationPicker, {
	
	initializePicking : function(){
		this.button = new Element('a', { 'class' : 'PickerLink', 'href' : this.associations_href }).update('Pick ' + this.CONFIG["associated_items"].capitalize());
		this.node.next().insert({ bottom : this.button });
		this.button.observe('click', this.launchAssociationPickerWindow.bindAsEventListener(this));
	},
	
	initializeControls : function(row){
		var positioning = row.down('.' + this.CONFIG['controls_class']);
		if (positioning) {
			for (x=0;x<4;x++){
				var reorder = positioning.down('img', x);
				if (reorder)
					{ reorder.observe('click', this.changePosition.bindAsEventListener(this));	}
			}
			var remove = positioning.down('img', 4);
			if (remove)
				{ remove.observe('click', this.removeAssociation.bindAsEventListener(this)); }
		}
	},
	
	createPickerInterface : function(){
		this.fieldset = new Element('fieldset', { 'class' : 'PickerInterface' });
		this.table = new Element('table', { 'class' : 'PickerTable' });
		this.fieldset.insert({ top : this.table });
		this.table.update(this.CONFIG['table_cols_markup']);
		this.tbody = new Element('tbody');
		this.table.insert({ bottom : this.tbody });
		if (this.associations.length < 1) {
			this.addPlaceholder();
		} else {
			this.node.value = "";
			this.associations.each(function(item){
				this.addAssociation(item);
			}, this);
		}
		this.node.insert({ after : this.fieldset });
		this.node.hide();
	},
	
	changePosition : function(e){
		var clicked = e.findElement();
		var row = clicked.up('tr');
		if (row) {
			switch(clicked.className){
				case 'move-to-top' : 
					this.tbody.insert({ top : row });
					break;
				case 'move-to-bottom' :
					this.tbody.insert({ bottom : row });
					break;
				case 'move-down' :
					if (row.next()) { 
						row.next().insert({ after : row });
					}
					break;
				case 'move-up' :
					if (row.previous()) { 
						row.previous().insert({ before : row });
					}
					break;
			}
		}
		this.updateAssociationData();
	},
	
	addAssociation : function(response){
		if (this.isAValidAssociation(response['id'])) {
			this.removePlaceholder();
			var row = new Element('tr', { 'id' : this.CONFIG['row_prefix'] + response['id'] });
			var title = new Element('td').update(response['title'] + "<input class='value' type='hidden' value='" + response['id'] + "' />");
			var controls = new Element('td', { 'class' : this.CONFIG["controls_class"] }).update(this.CONFIG['controls_markup']);
			row.insert({ top : title }).insert({ bottom : controls });
			this.tbody.insert({ bottom : row });
			this.updateAssociationData();
			this.initializeControls(row);
		} else {
			alert("This association has already been made!");
		}
	},
	
	removeAssociation : function(e){
		var to_remove = e.findElement().up('tr');
		if (to_remove) {
			to_remove.remove();
		}
		this.updateAssociationData();
		if (this.node.value.empty()) { this.addPlaceholder(); }
	},
	
	addPlaceholder : function(){
		var placeholder = new Element('tr', { 'class' : 'Placeholder' }).update( new Element('td', { 'colspan' : this.CONFIG["table_cols_length"] }).update("There are currently no associated " + this.CONFIG["associated_items"] + "."));
		this.tbody.insert({ bottom : placeholder });
		// Placeholder == No Associations. Either it's empty -- in which case clearing
		// it should have no effect -- or the previous values just didn't return
		// anything from the server: e.g. invalid associations. Let's wipe the
		// slate clean to avoid having crummy data hanging around in the future.
		this.node.value = "";
	},
	
	removePlaceholder : function(){
		var placeholder = this.tbody.down('.Placeholder');
		if (placeholder) { placeholder.remove(); }
	},
	
	isAValidFormSubmission : function(){
		return true;
	},
	
	updateAssociationData : function(){
		this.val = [];
		this.table.select('tr').each(function(row){
			var value = row.down('.value');
			var associated_value = row.down('.associated-value');
			if (value && associated_value) {
				this.val.push(value.value + "|" + associated_value.value);
				if (!associated_value.value.empty()) {
					var warning = associated_value.up().down('.PickerWarning');
					if (warning) { warning.remove(); }					
				}
			}
			if (value && !associated_value) {
				this.val.push(value.value);
			}
		}, this);
		this.node.value = this.val.join(",");
		this.node.fire('input:updated');
		if (this.initialized) {
			this.updateCallback(this);
		}
	}
	
});

MultipleAssociationPicker.CONFIG = {
	
	// Note that these callbacks each take (this) as an argument, so that you
	// can use the behavior's scope within the CONFIG'd functions.
	initialize_callback : function(scope) { },
	update_callback : function(scope) { },
	
	picker_popup_param : "",
	picker_popup_value : "",
	associated_items : "widgets",
	associations_href : "/admin/picker/associated_widgets",
	fieldset_class_selector : ".content-type-part",
	requires_unique_associations : false,
	row_prefix : "association_id",
	table_cols_length : '2',
	table_cols_markup : '<col width="80%" /><col width="20%" />',
	controls_class : "controls",
	controls_markup : '<img class="move-to-top" src="/images/admin/move_to_top.png" alt="Move to top" name="NoFilter" /> <img class="move-up" src="/images/admin/move_higher.png" alt="Move up" name="NoFilter" /> <img class="move-down" src="/images/admin/move_lower.png" alt="Move down" name="NoFilter" /> <img class="move-to-bottom" src="/images/admin/move_to_bottom.png" alt="Move to bottom" name="NoFilter" /><img class="remove-part" src="/images/admin/remove.png" alt="Remove part" name="NoFilter" />'
};
