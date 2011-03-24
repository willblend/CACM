Object.extend(Number.prototype, {
  toFilesize : function(){
    if (this >= (1024 * 1024)) {
      return (Math.ceil((this * 100) / (1024 * 1024)) / 100).toString() + " MB";

    } else if (this >= 1024 ) {
      return (Math.ceil((this * 100) / (1024)) / 100).toString() + " KB";

    } else {
      return this.toString() + " bytes";
    }
  }
});


Object.extend(String.prototype, {

	getHash : function() {	
		var idx = this.indexOf("#");
		return (idx >= 0 ) ? this.substring(idx + 1) : null;
	},

	toSlug : function() {
    return this.gsub(/['"]/, "").gsub(/[^A-Za-z0-9]/, " ").strip().gsub(/ +/, "-").toLowerCase();
	}

});

/* ======================================================================== */

Object.extend(Prototype.Browser, {
	// looks for IE6 so we can set display properties like min-height vs. height
	IE6 : (function(){
		return (/msie 6/i.test(navigator.userAgent)) && !(/opera/i.test(navigator.userAgent)) && (/win/i.test(navigator.userAgent));
	})(),

	// look for old, bug-ridden versions of WebKit
	WebkitOld : (function(){
		// Safari: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/419 (KHTML, like Gecko) Safari/419.3
		// WebKit (as of 2007-07-04): Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/522+ (KHTML, like Gecko) Safari/419.3
		var regex = navigator.userAgent.match(/AppleWebKit\/(\d+)/);
		return (regex && regex.length == 2) ? (parseInt(regex[1]) <= 419) : false;
	})()

});

// this fixes the constructor problem in old versions of WebKit
function fixWebKitInheritanceBug(obj) {
	if (Prototype.Browser.WebkitOld) obj.prototype.constructor = obj;
}

/* ======================================================================== */

// convenience function: $$ with scope as first arg
function $$S() {
	var args = $A(arguments), scope = args.shift();
  return Selector.findChildElements(scope, args);
}

/* ======================================================================== */

// returns form elements by form_name and element name
// useful for returning a group of radio buttons as an array
function $FE(form_name, element_name) {
	if ( (typeof(form_name) != 'string') || typeof(element_name) != 'string' ) { return; }

	var f = document.forms[form_name] || $$("FORM#" + form_name)[0];
	var elements = f.elements[element_name];

	if (!f || !elements) {
		return null;
	
	} else {
		return elements;
	}
}

/* ======================================================================== */

// fixes browsers which don't implement <OPTION disabled="disabled">
document.observe("dom:loaded", function(){
	function fixDisabledOptions() { $A(this.options).each(function(opt) { if ($(opt).disabled) opt.selected = false; }); }
	$$("SELECT").each(function(sel){ Event.observe(sel, 'change', fixDisabledOptions.bind(sel)); });
});

/* ======================================================================== */

// fixes LABELs not triggering focus on form elements when they have IMG elements inside
if (Prototype.Browser.IE || Prototype.Browser.WebKit) {
	document.observe("dom:loaded", function(){
		$$("LABEL IMG").each(function(image) {
			var el = $(image.parentNode.getAttribute('for') || image.parentNode.attributes['for'].nodeValue);
			if (el) { image.observe('click', function(){ el.focus(); }); }
		});
	});
}

/* ======================================================================== */

// site namespace constructor
function Site(globals) {

	this.GLOBALS = Object.extend({
		active_class : "Active",
		expanded_class : "Expanded",
		disabled_class : "Disabled",
		deleted_class : "Deleted",
		selected_class : "Selected",
		hover_class : "Hover",
		link_class : "Link",
		dhtml_link_class : "LinkDHTML",
		img_path : "/images/",
		ajax_update_delay : 100 // ms
	}, globals || { });

	/* ---------------------------------------------------------------------- */

	// boolean; to enable console debugging, pass in "DEBUG" as a query param
	this.DEBUG = function() {
		var qs = window.location.search.toQueryParams();
//		console.log("Object.keys(qs).indexOf(\"DEBUG\") = " + Object.keys(qs).indexOf("DEBUG"));
		return (Object.keys(qs).indexOf("DEBUG") > -1) || false; // NOTE: make sure this is false for production
	}();

	// tiny debug wrapper (being nice to IE/Win)
	this.debug = function(msg) {
		// bail out if debugging is off
		if (!this.DEBUG) { return; }

		// accept an array of strings and use them as lines
		if (msg instanceof Array) {
			msg = msg.join("\n");
		}

		try {
			// ff and safari go here
			console.log(msg);

		} catch(e) {
			// IE gets this

			// open the win if no win exist
			if (!this.debug_win) {
				this.debug_win = window.open("","","");
				this.debug_win.document.open();
			}

			// simple HTML regex
			msg = msg.replace(/</g, "&lt;");
			msg = msg.replace(/>/g, "&gt;");

			// user may have closed the window, so reopen if necessary
			try {
				this.debug_win.document.write("");
			} catch(e) {
				this.debug_win = window.open("","","");
				this.debug_win.document.open();			
			}

			// finally output the msg
			this.debug_win.document.write("<pre style='font-size: 80%; margin: .5em 0 2em 0;'>" + msg + "</pre>");

		}
	}; // END: debug()

	/* ---------------------------------------------------------------------- */

	this.addFeature = function(feature_name, config) {
		// don't add the same feature twice
		if (this.Features[feature_name]) {
			// FIXME: should really throw error here
			return;
		}

		// take care of 'special' methods
		delete config.widget_instances;
		delete config.storeWidgetInstance;
		delete config.removeWidgetInstance;
		delete config._setupElements;

		// add the feature
		this.Features[feature_name] = Object.extend({
			widget_instances : { },

			storeWidgetInstance : function(id, widget, overwrite) {	
				if (typeof(this.widget_instances[id]) === 'undefined') {
					this.widget_instances[id] = widget;
					return true;

				} else if (overwrite === true) {
	//			this.debug(["hash \"" + id + "\" already exists in elements... OVERWRITING", "this.elements[" + id + "] = " + this.elements[id].toString() ]);
					this.widget_instances[id] = widget;
					return true;

				} else {
	//			this.debug(["hash \"" + id + "\" already exists in elements", "this.elements[" + id + "] = " + this.elements[id].toString() ]);
					return false;
				}
			}, // END: store()

			removeWidgetInstance : function(id) {
				if (typeof(this.widget_instances[id]) !== 'undefined') {
					delete this.widget_instances[id];
					return true;

				} else {
	//			this.debug("hash \"" + id + "\" not found");
					return false;
				}
			},

			initialize : Prototype.emptyFunction,

			setupElements : Prototype.emptyFunction,

			_setupElements : function(root_node) {
				// accept an aribitrary root_node (for use with AJAX updates)
				root_node = $(root_node) || document;

				this.setupElements(root_node);
			}

		}, config || { });
	
		// initialize it immediately
		this.Features[feature_name].initialize();

		// if the DOM ready event wasn't called yet, queue up setupElements
		if (!this['DOM_LOADED']) {
			document.observe("dom:loaded", this.Features[feature_name]._setupElements.bind(this.Features[feature_name], document));

		// if it's after DOM ready, then just call our function ASAP
		} else {
			this.Features[feature_name]._setupElements();
		}

	};

	// a hash to store our Features
	this.Features = { };

	// set a flag so we know if the DOM has been loaded
	this.DOM_LOADED = false;

	// this relies on the fact that new Site() is the first function called.
	document.observe("dom:loaded", function() {
		this.DOM_LOADED = true;
	}.bind(this));

}

/* ======================================================================== */

var PageWidget = Class.create({
	node : null,

	// basic, useless initialize method
	initialize : function(id, options) {
		this.node = $(id);

		this.setOptions(options);
	},

	setOptions : function(config) {
		this.CONFIG = Object.extend(Object.clone(this.constructor.CONFIG), config || {});
	}
});

PageWidget.CONFIG = { };

fixWebKitInheritanceBug(PageWidget);
