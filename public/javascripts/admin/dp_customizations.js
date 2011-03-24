// back-end JS file for Radiant
// ---------------------------------------------------------------------------

var SelectList = Behavior.create({
	initialize : function(on_change_handler) {

		var select_node = new Element('select', {'class' : 'select-nav'});

		// try and find a title to insert as the first OPTION, and then remove it
		var title_text = this.element.down('.SelectList-Title');
		if (title_text) {
			select_node.appendChild(new Element('option', {'value' : ''}).update(title_text.innerHTML.stripTags()));
			title_text.remove();
		}

		// add a blank OPTION
		select_node.appendChild(new Element('option', {'value' : ''}).update(""));

		// iterate over the links in the UL and create OPTIONs from them
		this.element.select('li a').each(function(a) {
			select_node.appendChild(new Element('option', {'value' : a.href}).update(a.innerHTML.stripTags()));
		});

		// assign the onChange event handler to the new SELECT
		var handler = on_change_handler || this.selectChangeHandler;
		select_node.observe('change', handler.bindAsEventListener(this, select_node));

		// replace the UL with the SELECT
		this.element.down('ul').replace(select_node);

		// remove the class that created the hook
		this.element.removeClassName('SelectList');
	},

	selectChangeHandler: function(e, select_node){
		var url = $F(select_node);
		if (!url.blank()) {
			window.location = url;
		}
	}
});

Event.addBehavior({
	'div.SelectList' : SelectList
});

// ---------------------------------------------------------------------------

var FormFieldTitle = Behavior.create(PageWidget, {
	initialize : function(options) {
		this.setOptions(options);

		switch(this.element.nodeName.toUpperCase()) {

			case 'INPUT':
			case 'TEXTAREA':
				// skip this whole thing if the element is disabled or if there's no title attribute
				if ( this.element.disabled || 
				    (typeof(this.element.title) == 'undefined') || 
				    this.element.title.blank()
				) { return; }

				this.restoreHelperText(this.element);

				// hook up the events
				this.element.observe('focus', this.clearHelperText.bind(this, this.element));
				this.element.observe('blur', this.restoreHelperText.bind(this, this.element));
				break;

			case 'SELECT':
				// create new option and prepend it to the options array
				var opts = { value : "" };
				if (this.element.selectedIndex == 0) {
          this.element.options[0].selected = "";
				  opts['selected'] = "selected";
				};
				this.element.insert({ 'top': new Element('option', opts).update(this.element.title) });
				break;

			default: break;
		};

		var f = $(this.element.form);

		if (Object.isUndefined(f['fields_with_titles'])) {
			// set up an array to store the elements to clear later
			f.fields_with_titles = $A([]);

			// set up the FORM to clear out our titles onsubmit
			f.observe('submit', this.clearHelperTextOnSubmit.bindAsEventListener(this, f));
		}

		f.fields_with_titles.push(this.element);
	},

	clearHelperText : function(el) {
		if (el.value == el.title) {
			el.value = '';
			el.removeClassName(this.CONFIG['disabled_class']);
		}
	},

	restoreHelperText : function(el) {
		if (el.value.blank() || el.value == el.title) {
			el.value = el.title;
			el.addClassName(this.CONFIG['disabled_class']);
		}
	},

	clearHelperTextOnSubmit : function(e, f) {
		f.fields_with_titles.each(function(el){
			this.clearHelperText(el);
		}, this);
	}

});

FormFieldTitle.CONFIG = {
	show_title_class : "ShowTitle",
	disabled_class : 'Disabled'
};

Event.addBehavior({
	'.ShowTitle' : FormFieldTitle
});

// ---------------------------------------------------------------------------

var AutoSubmitField = Behavior.create(PageWidget, {
	initialize : function(options) {
    $(this.element.form).down('.FormAction').hide();
	},
	onchange : function(e) {
    if (
      // OPTIONs must have values!
      !$F(this.element).blank() ||

      // but, we allow an OPTION with no value ("[All XXXXXX]") to be selected and navigated to as well
      ( $F(this.element).blank() && this.element.options[this.element.selectedIndex].text.toLowerCase().startsWith("[all") )
    ) {
      e.element().form.submit();
    }

	}
});

Event.addBehavior({
	'.AutoSubmitField' : AutoSubmitField
});

// ---------------------------------------------------------------------------

var DependentSelectOptions = Behavior.create(PageWidget, {
	initialize : function(dependencies, options) {
    this.setOptions(options); // { 'disable_elements' : true, 'retrigger_previously_selected' : false }

		this.nodes = $A($(this.element).options);

		this.dependencies = $H(dependencies) || $H(); // obj hash: { 'radio_button_id' : { 'activate' : function(){ }, 'deactivate' : function(){ } } }
		this.dependency_list = this.dependencies.keys() || []; // array of Object.keys(dependencies)

  	this.previously_selected = [];  // array of OPTION elements previously selected

		this.element.observe('change', this.updateDependencies.bindAsEventListener(this));

		this.updateDependencies();
	},

  getOptionTextOrOptionValue : function(opt) {
    return this.CONFIG['use_labels_instead_of_values'] ? opt.text : opt.value;
  },

	updateDependencies : function(e) {
		var previously_selected = this.previously_selected;
		
		// we only care about getting options with dependencies
		var dependent_opts = this.nodes.partition(function(opt){
			return this.dependency_list.include(this.getOptionTextOrOptionValue(opt));
		}, this)[0];

		// just storing the currently selected options that have dependencies, to optmize things
		var currently_selected = [];

		// just the OPTIONs with dependencies
		dependent_opts.each(function(opt){
			if (opt.selected) {
				// remember that the option is selected
				currently_selected.push(opt);

			// if not selected
			} else {
				// only deactivate the dependency if was selected before... or if retriggering is enabled
				if (previously_selected.include(opt) || this.CONFIG['retrigger_previously_selected']) {
					this.dependencies.get(this.getOptionTextOrOptionValue(opt)).deactivate();
				}
			}
		}, this);

		currently_selected.each(function(opt){
  		// only activate the dependency if wasn't selected before... or if retriggering is enabled
  		if (!previously_selected.include(opt) || this.CONFIG['retrigger_previously_selected']) {
				this.dependencies.get(this.getOptionTextOrOptionValue(opt)).activate();
  		}
		}, this);

		// remember currently_selected for next time
		this.previously_selected = currently_selected;
	}
  
});

DependentSelectOptions.CONFIG = {
  'retrigger_previously_selected' : false,
  'disable_elements' : true,
  'use_labels_instead_of_values' : false
};
