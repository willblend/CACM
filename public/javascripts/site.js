// ===========================================================================
// site.js

// HOWTO: make site_compressed.js in TextMate
// Menu:
//	Bundles >>
//    Javascript Tools >>
//      Compress current file (command+control+C)
//			Save file (site_compressed.js)
// And you're done!

// But wait! What if you don't have the JavaScript Tools bundle?
		
// 1. Get the bundle:
//		http://andrewdupont.net/2006/10/01/javascript-tools-textmate-bundle/

// or...
		
// 2. Use the compresser at: 
//		http://javascriptcompressor.com/ (make sure shrink variables is checked)

// ---------------------------------------------------------------------------

if (!Prototype.Browser.IE6) {
	// looks for IE6 so we can set display properties like min-height vs. height
	Prototype.Browser.IE6 = (function(){
		return (/msie 6/i.test(navigator.userAgent)) && !(/opera/i.test(navigator.userAgent)) && (/win/i.test(navigator.userAgent));
	})();
}

// ---------------------------------------------------------------------------

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


// ===========================================================================
// utils.js

// IE/win background image flicker fix
// http://evil.che.lu/2006/9/25/no-more-ie6-background-flicker
try { document.execCommand('BackgroundImageCache', false, true); } catch(e) {}
	
// ---------------------------------------------------------------------------

if (!String.prototype.getHash) {
	String.prototype.getHash = function() {	
		var idx = this.indexOf("#");
		return (idx >= 0 ) ? this.substring(idx + 1) : null;
	};
}

if (!String.prototype.toSlug) {
	String.prototype.toSlug = function() {	
    return this.gsub(/['"]/, "").gsub(/[^A-Za-z0-9]/, " ").strip().gsub(/ +/, "-").toLowerCase();
	};
}

// ---------------------------------------------------------------------------

/* NOTE: the following code was extracted from the UFO source and extensively reworked/simplified */

/* Unobtrusive Flash Objects (UFO) v3.20 <http://www.bobbyvandersluis.com/ufo/>
	Copyright 2005, 2006 Bobby van der Sluis
	This software is licensed under the CC-GNU LGPL <http://creativecommons.org/licenses/LGPL/2.1/>
*/

function createCSS(selector, declaration) {
	// test for IE
	var ua = navigator.userAgent.toLowerCase();
	var isIE = (/msie/.test(ua)) && !(/opera/.test(ua)) && (/win/.test(ua));

	// create the style node for all browsers
	var style_node = document.createElement("style");
	style_node.setAttribute("type", "text/css");
	style_node.setAttribute("media", "screen"); 

	// append a rule for good browsers
	if (!isIE) style_node.appendChild(document.createTextNode(selector + " {" + declaration + "}"));

	// append the style node
	document.getElementsByTagName("head")[0].appendChild(style_node);

	// use alternative methods for IE
	if (isIE && document.styleSheets && document.styleSheets.length > 0) {
		var last_style_node = document.styleSheets[document.styleSheets.length - 1];
		if (typeof(last_style_node.addRule) == "object") last_style_node.addRule(selector, declaration);
	}
}


// ===========================================================================
// base_behaviors.js

// this is the base Behavior Class. all of our widgets should inherit from this.
// NOTE: not sure how much we'll use it for things other than the setOptions method.
var PageWidget = Behavior.create({
	initialize : function(options) {
		this.setOptions(options);
	},

	setOptions : function(config) {
		this.CONFIG = Object.extend(Object.clone(this.constructor.CONFIG), config || {});
	}
});

PageWidget.CONFIG = { };

// ---------------------------------------------------------------------------


// ---------------------------------------------------------------------------



// ===========================================================================
// DHTMLMenu.js

var DHTMLMenu = Behavior.create(PageWidget, {
  initialize: function(config){
		this.setOptions(config);

		this.submenus = { };

		// get all the top-level LIs in the menu and iterate over them, adding event handlers
		this.element.immediateDescendants().each(function(item){
			item.observe("mouseover", this.mouseoverHandler.bindAsEventListener(this, item));
			item.observe("mouseout", this.mouseoutHandler.bindAsEventListener(this, item));

			this.submenus[item.id] = item.down().next();
		}, this);

	},

	initialized       : false,
	menu_hide_timeout : null,  // the JS timeout ID for hiding the menu
	menu_show_timeout : null,  // the JS timeout ID for showing the menu
	last_menu_on      : null,  // the DOM object of the waiting to close

	mouseoverHandler : function(e, item) {
		// stop the menu from closing/opening (this gets called a lot)
		clearTimeout(this.menu_hide_timeout);
		clearTimeout(this.menu_show_timeout);

		// if we're mousing over the menu for the first time, set a timeout so the menu doesn't show up accidentally.
		if (this.last_menu_on == null) {
			this.menu_show_timeout = setTimeout(this.showMenu.bind(this, item),	this.CONFIG["menu_show_time"]);

		// if there's already a menu on, then we know the user is expecting to see another one, so show it immediately.
		} else if (this.last_menu_on != item) {
			this.showMenu(item);
		}
	},

	mouseoutHandler : function(e, item) {
		// clear the existing show/hide timeouts (this gets called a lot)
		clearTimeout(this.menu_hide_timeout);
		clearTimeout(this.menu_show_timeout);

		// only "close" the menu in a little bit if we're over a menu with submenus, otherwise, close it right now
		if (this.submenus[item.id]) {
			this.menu_hide_timeout = setTimeout(this.hideMenu.bind(this, item),	this.CONFIG["menu_hide_time"]);

		} else {
			this.hideMenu(item);
		}
	},

	// shows the menu
	showMenu : function(item) {
		// hide the last menu shown
		if (this.last_menu_on != null) { this.hideMenu(this.last_menu_on); }

		// adding the "hover" class turns on the menu
		item.addClassName(this.CONFIG['hover_class']);

		// insert the IFRAME for IE
		if (Prototype.Browser.IE6) {
			// get at the submenu for dimension info
			var submenu = this.submenus[item.id];
			if (submenu) {
				var iframe = submenu.next();

				if (submenu && !iframe) {
					this.createIframe(item, {
						'left'   : submenu.offsetLeft + "px",
						'height' : submenu.offsetHeight + "px",
						'width'  : submenu.offsetWidth + "px"
					});
				}
			}
		}

		// store the last item on
		this.last_menu_on = item;

	}, // END: showMenu()

	// hide the menu
	hideMenu : function(item) {
		// nothing to hide
		if (item == null) return;

		// removing the "hover" class turns off the menu
		item.removeClassName(this.CONFIG['hover_class']);

		// remove the IFRAME for IE
		if (Prototype.Browser.IE6) {
			var submenu = this.submenus[item.id];
			if (submenu) {
				var iframe = submenu.next();
				if (submenu && iframe) {
					item.removeChild(iframe);
				}
			}
		}

		this.last_menu_on = null;
	}, // END: hideMenu()

	// makes an IFRAME the exact size of the menu so elements underneath it are covered
	// (IE-only)
	createIframe : function(node, style) {
		new Insertion.Bottom(node, (new Template('<iframe class="' + this.CONFIG['iframe_class'] + '" frameborder="0" scrolling="no" style="width: #{width}; height: #{height}; left: #{left};"><\/iframe>')).evaluate(style));
	}

});

DHTMLMenu.CONFIG = {
	submenu_class  : "SubMenu",   // the DOM class of the menu container
	hover_class    : "Hover",     // the class to give the top-level LI to "activate" the menu
	menu_hide_time : 500,         // time to keep the menus on after mouseout; in ms
	menu_show_time : 100,         // threshold o
	iframe_class   : "IframeFix"  // used for IE
};

// ===========================================================================
// SelectList.js

var SelectList = Behavior.create(PageWidget, {
	initialize : function(config) {
    this.setOptions(config);

		var select_node = new Element('select', {'class' : 'select-nav'});

		// try and find a title to insert as the first OPTION, and then remove it
		var title_text = this.element.down('.' + this.CONFIG['title_class']);
		if (title_text) {
			select_node.appendChild(new Element('option', {'value' : ''}).update(title_text.innerHTML.stripTags()));
			title_text.remove();
		}

		// add a blank OPTION
		select_node.appendChild(new Element('option', {'value' : ''}).update(""));

		// iterate over the links in the UL and create OPTIONs from them
		this.element.select('li a').each(function(a) {
      var options = { 'value' : a.href };
      if (a.up('LI').hasClassName(this.CONFIG['selected_class'])) { options['selected'] = 'selected'; }

			select_node.appendChild(new Element('option', options).update(a.innerHTML.stripTags()));
		}, this);

		// assign the onChange event handler to the new SELECT
		select_node.observe('change', this.CONFIG['onchange_handler'].bindAsEventListener(this, select_node));

		// replace the UL with the SELECT
		this.element.down('ul').replace(select_node);

		// remove the class that created the hook
		this.element.removeClassName(this.CONFIG['class_name']);
	}
});

SelectList.CONFIG = {
  'class_name'       : 'SelectList',
  'title_class'      : 'SelectList-Title',
  'selected_class'   : 'Selected',
  'onchange_handler' : function(e, select_node){
		var url = $F(select_node);
		if (!url.blank()) {
			window.location = url;
		}
	}
};

// ---------------------------------------------------------------------------

var TextResizer = Behavior.create(PageWidget, {
	initialize : function(target, config){
		this.resizing_target = $(target);
		if (!this.resizing_target) { return; }
		this.setOptions(config);
		this.font_sizes = this.CONFIG['font_sizes'];
		this.buttons = this.element.select('.' + this.CONFIG['default_button_class']);
		if (!this.font_sizes.length == this.buttons.length) { return; }
		for (x=0;x<this.CONFIG['font_sizes'].length;x++) {
			this.buttons[x].observe('click', this.resizeClickHandler.bindAsEventListener(this, x));
		}
		if (this.element.select('.'+this.CONFIG['active_button_class']).length == 0) {
			this.buttons[0].addClassName(this.CONFIG['active_button_class']);
		}
	},
	resizeClickHandler : function(click, level){
		click.stop();
		this.resizeText(level);
	},
	resizeText : function(level) {
		if (!this.buttons[level].hasClassName(this.CONFIG['active_button_class'])) {
			this.element.select('.' + this.CONFIG['active_button_class']).invoke('removeClassName', this.CONFIG['active_button_class']);
			this.buttons[level].addClassName(this.CONFIG['active_button_class']);
			this.resizing_target.setStyle({ fontSize : this.font_sizes[level] });
		}
	}
});

TextResizer.CONFIG = {
	default_button_class : 'Link',
	active_button_class : 'active',
	font_sizes : ['100%','112.5%','125%']
};

// ---------------------------------------------------------------------------

// toggles the site search box between the CACM search and search on the digital
// library. the initial state is always pointing to CACM search. the CF_ID
// and CF_TOKEN are tucked into hidden inputs in this form, and are empty if
// the current user is anonymous.

var SiteSearchToggler = Behavior.create({
	initialize : function(){
		this.form_node = this.element.down('form');
		this.form_input = $('site_search_query');
		if (!this.form_node || !this.form_input) { return; }
		var toggler = this.element.down('.toggle'); // contains the radio buttons
		if (toggler) {
			toggler.setStyle({ display : 'block' });
			this.cacm_search = $('site_search_communications');
			this.dl_search = $('site_search_digital_library');
			this.dl_user_id = $('search_cf_session_id'); // hidden input
			this.dl_user_token = $('search_cf_session_token'); // hidden input
			
			// if all of these are present, we can activate the toggling:
			if (this.cacm_search && this.dl_search && this.dl_user_id && this.dl_user_token) {
				this.cacm_search_active = true;
				this.dl_user_id.remove();
				this.dl_user_token.remove();
				this.cacm_search.observe('change', this.toggleCommunicationsSearchForm.bindAsEventListener(this));
				this.dl_search.observe('change', this.toggleDigitalLibrarySearchForm.bindAsEventListener(this));
			}
		}
	},
	toggleCommunicationsSearchForm : function(e){
	  
	  // set form to search via Communications
	  
		if (!this.cacm_search_active) {
			this.form_node.action = "/search";
			this.form_node.method = "get";
			this.form_node.target = "";
			this.form_input.name = "q";
			this.cacm_search_active = true;
			// remove the CFID/TOKEN inputs so they don't get queries put into the GSA
			this.dl_user_id.remove();
			this.dl_user_token.remove();
		}
	},
	toggleDigitalLibrarySearchForm : function(e){
	  
	  // set form to search the Digital Library
	  
		if (this.cacm_search_active) {
			this.form_node.action = "http://portal.acm.org/results.cfm?coll=ACM&dl=ACM";
			// if we've got some CF credentials, tack them onto the action
			if (!this.dl_user_id.value.empty() && !this.dl_user_token.value.empty()) {
				this.form_node.action += "&CFID=" + this.dl_user_id.value + "&CFTOKEN=" + this.dl_user_token.value;
			}
			this.form_node.method = "post";
			this.form_node.target = "_blank";
			this.form_input.name = "query";
			// insert the hidden inputs so that the POST will include the vars
			this.form_node.insert({ bottom : this.dl_user_token });
			this.form_node.insert({ bottom : this.dl_user_id });
			this.cacm_search_active = false;
		}
	}
});

// ---------------------------------------------------------------------------

var AutoSubmitField = Behavior.create(PageWidget, {
	initialize : function(options) {
    $(this.element.form).down('.FormAction').hide();
	},
	onchange : function(e) {
    if ($F(this.element).blank()) { return; }

    e.element().form.submit();
	}
});

// ---------------------------------------------------------------------------

// this will attach an off-site link icon to any link pointing off-site in the
// scope defined in the block at the bottom of this file, which is any link
// inside #BodyWrapper. It ignores email links, anchor links, and blank links

var OffSiteLinkalizer = Class.create({
	
	offsite_image_markup : '&nbsp;<img src="/images/icon.external-link.gif" alt="External Link" title="This link opens off-site" width="8" height="8" class="icon" />',
	
	initialize : function(node){
		this.node = $(node);
		if (!this.node) { return; }
		this.node.select("A").each(function(a) { this.initializeOffSiteLink(a); }, this);
	},
	
	initializeOffSiteLink : function(link){
		// don't include local domain or mailto. don't include anchor links or empty href's or JS calls.
		if (!link.href.include(document.location.hostname) && !link.href.include('mailto') && link.href.indexOf("#") != 0 && !link.href.blank()&&!link.href.include("javascript:")) {
			link.target = "_blank";
			if (!link.innerHTML.toLowerCase().include("<img")) {
				link.insert({ bottom : this.offsite_image_markup });
			}
		}
	}
	
});

// ---------------------------------------------------------------------------

// This controls the initial step of web account creation process. The user
// enters their email address and clicks submit. Depending on the state of the
// radio button (which is if they believe they have an existing ACM account)
// there are a few different ways to check, but the end result to the user is 
// the same -- if the email address exists in the system, they are asked to
// try logging in with the username connected to the email address they entered
// or, if the email address is not found, the email address they entered is
// saved in a potential profile and they are sent to the next page, which asks
// them to check their email and continue with the web account creation flow.

var CreateWebAccountForm = Class.create({
	initialize : function(form){
		this.form_element = $(form);
		if (!this.form_element) { return; }
		this.form_submit = this.form_element.down('input[type="image"]');
		this.form_email_input = $('email');
		this.form_radio_button_true = $('member_true');
		if (!this.form_submit || !this.form_radio_button_true || !this.form_email_input) { return; }
		this.form_element.observe('submit', this.formSubmitHandler.bindAsEventListener(this));
	},
	formSubmitHandler : function(e){
		e.stop();
		// ripped from validation.js
		if ($F(this.form_email_input).match(/^([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)$/)) {
			new Ajax.Request('/accounts/verify_membership', {
				parameters : { 'email' : this.form_email_input.value, 'existing_account' : this.form_radio_button_true.checked },
				onSuccess : this.verificationResponseSuccessHandler.bind(this),
				onFailure : this.verificationResponseFailureHandler.bind(this)
			}, this);
		} // else, the email address wasn't valid, so we'll let validation.js fix first.
	},
	verificationResponseSuccessHandler : function(transport){
		if (transport.responseText) {
			if (transport.responseText.empty()) {
				// no memberships were found with the account, but the user didn't even check it. proceed.
				this.form_element.submit();
			} else { // some markup was returned, let's show it...
				this.modal_wrapper = new Element('div', { 'id' : 'ajax-modal' }).update(transport.responseText);
				this.form_element.insert({ bottom : this.modal_wrapper });
				this.modal_wrapper.show();
				// grab the form in the modal and change the action to https
			  var form = this.modal_wrapper.down('form');
			  if (form) {
			    // if .action gives us the full path, gsub out the http
			    if (form.action.match(/^http/)) {
			      form.setAttribute('action', form.action.gsub('http','https'));
			    } else {
			      // else, https + document.domain + form.action
			      form.setAttribute('action', "https://" + document.domain + form.action);
			    }
			  }
			}
		} else {
			// hmm. blank response? must not have found anything. submit the form!
			this.form_element.submit();
		}
	},
	verificationResponseFailureHandler : function(transport){
		// Something broke with the AJAX request, so let's just carry on as if
		// we didn't have JS.
		this.form_element.submit();
	}
});

// ---------------------------------------------------------------------------

// When this behavior is attached to a widget it turns into a print link, with
// a generic window.print(); return false;
// The initialize callback is used to display the print link, as without JS
// the link is useless. Therefore the link itself is hidden by CSS.

var PrintLink = Behavior.create(PageWidget, {
	initialize : function(callback){
		this.initializeCallback = callback || Prototype.emptyFunction;
		this.link = $(this.element);
		if (!this.link) { return; }
		this.link.observe('click', function(e){ window.print(); return false; }.bind(this));
		this.initializeCallback();
	}
});

// ---------------------------------------------------------------------------

// These display the widget help boxes. There are a few event rules: the window
// will display when:
// (a) the user clicks on the header of the widget
// (b) the user hovers over the header of the widget for 2.5 seconds
// (c) the user clicks on the "i" button
// Once the widget help box is displayed, the only way for it to vanish is if
// the user clicks close. The small "i" button is displayed whenever the user
// hovers the mouse over the widget, and vanishes when the mouse exits. The
// "hover counter" (the # of seconds till the help box appears) is also reset
// whenever the user moves the mouse away from the widget.

var WidgetHelp = Behavior.create(PageWidget, {
	
	close_button : '<a href="#" class="Close">[X]</a>',
	currently_visible : false,
	currently_hovering : false,
	mouse_hover_counter : 0,
	
	initialize : function(config){
		this.setOptions(config);
		this.wrapper = this.element.up("div"); // fetch the widget-wrapper DIV
		this.createWidgetHelpViews();
		if (this.node && this.hover_eye) {
			this.wrapper.setStyle({ position : "relative" });
			this.element.addClassName("WidgetHelpHeader");
			this.element.observe('click', this.displayHelpView.bindAsEventListener(this));
			this.element.observe('mouseover', this.mouseEnterHandler.bindAsEventListener(this));
			this.element.observe('mouseout', this.trackMouseOuts.bindAsEventListener(this));
			this.close_node.observe('click', this.closeNodeClickHandler.bindAsEventListener(this));
			this.hover_eye.observe('click', this.displayHelpView.bindAsEventListener(this));
			this.wrapper.observe('mouseover', this.showHoverEye.bindAsEventListener(this));
			this.wrapper.observe('mouseout', this.hideHoverEye.bindAsEventListener(this));
		}
	},
	
	createWidgetHelpViews : function(){
		this.node = new Element('div', {
			'class' : 'WidgetHelp',
			'style' : 'border: 1px solid '+this.CONFIG["border_color"]+'; display: none;'
		});
		this.node.innerHTML = "<p>" + this.CONFIG["help_text"] + "</p>" + this.close_button;
		this.element.insert({ after : this.node });
		this.close_node = this.node.down(".Close");
		this.hover_eye = new Element('span', {
			'class' : 'WidgetHelpHoverEye',
			'style' : 'display: none;'
		});
		this.wrapper.insert({ bottom : this.hover_eye });
	},
	
	headerClickHandler : function(){
		if (!this.currently_visible) {
			this.displayHelpView();
		}
	},
	
	mouseEnterHandler : function(){
		if (!this.currently_hovering) { this.currently_hovering = true; }
		this.trackMouseOver();
	},
	
	trackMouseOver : function(){
		if (this.currently_hovering && !this.currently_visible) {
			this.mouse_hover_counter += 10;
			if (this.mouse_hover_counter > 99) { // 2.5 seconds of hovering
				this.displayHelpView();
			} else {
				setTimeout(this.trackMouseOver.bind(this), 250);
			}
		}
	},
	
	trackMouseOuts : function(){
		if (this.currently_hovering) { this.currently_hovering = false; }
		this.mouse_hover_counter = 0;
	},
	
	displayHelpView : function(){
		this.node.setStyle({ display : "block" });
		this.currently_visible = true;
		this.hideHoverEye();
	},
	
	closeNodeClickHandler : function(e){
		e.stop();
		this.hideHelpView();
	},
	
	hideHelpView : function(){
		this.node.setStyle({ display : "none" });
		this.currently_visible = false;
	},
	
	showHoverEye : function(visible){
		if (!this.currently_visible) { this.hover_eye.setStyle({ display : "block" }); }
	},
	
	hideHoverEye : function(){
		this.hover_eye.setStyle({ display : "none" });
	}
});

WidgetHelp.CONFIG = {
	help_text : "<p>Call me Ishmael.</p>",
	border_color : "#0095c9"
};

// ---------------------------------------------------------------------------

// This attaches itself to all flash messages, but at the moment only will
// interact with the notices. They are moved to the head of the page inside
// a basic wrapper. The script waits 3 seconds and then slides it above the
// top of the page fold. This is disabled for errors so that the user doesn't
// have to worry about reading quickly (or missing it entirely) and also for 
// the beta flash message, which is static.

var ClosingFlash = Behavior.create({
	initialize : function(){
		
		// keep error flashes static
		if (this.element.id != "FlashError") {
		
		  if (this.element.id == "FlashComment") {
		    
		    // if this a comment notice, we're going to handle it differently.
		    var comment_block = $("comment");
		    if (comment_block) {
		      comment_block.insert({ after : this.element });
		      this.element.scrollTo();
		    }
		    
		  } else {
		    
		    // else, this is a regular flash notice.
		    this.element.addClassName("FloatingFlash");
  			this.flash_height = this.element.getHeight() + 1; // add 1 because we want to later have it 1 pixel out of sight
  			this.wrapper = new Element('div', {'style' : 'height: ' + this.flash_height + 'px;'});
  			var layout = $('LayoutWrapper');
  			if (layout) { // wrap our flash in a soon-to-be hidden wrapper
  				layout.insert({ top : this.wrapper.update(this.element) });
  				setTimeout(this.hideFlashMessage.bind(this), 3000);
  			}
		  }
		}
		
	},
	hideFlashMessage : function(){
		for (var x=0;x < this.flash_height;x++) {
			setTimeout(this.adjustFlashHeight.bind(this, x), 12*x);
		} // attach a timeout for every pixel increment, 12 milliseconds past the last
	},
	adjustFlashHeight : function(px){
		this.wrapper.setStyle({ marginTop : '-'+px+'px' });
	} // move the wrapper out of sight.
});

// ---------------------------------------------------------------------------
// DisabledOptionsHelper: fixes browsers which don't implement <OPTION disabled="disabled">

var DisabledOptionsHelper = Behavior.create({
  initialize : function(){
    if (!Prototype.Browser.IE) { return; }
    $A(this.element.options).each(function(opt){
      if (opt.disabled) { opt.style.color = "#666666"; }
    });
    this.updateCurrentIndex();
    this.element.observe('change', this.checkForDisabledSelection.bindAsEventListener(this));
  },
  updateCurrentIndex : function(){
    this.current_index = this.element.selectedIndex;
  },
  checkForDisabledSelection : function(){
    if (this.element.options[this.element.selectedIndex].disabled) {
      this.element.selectedIndex = this.current_index;
    } else {
      this.updateCurrentIndex();
    }
  }
});

// ---------------------------------------------------------------------------
// ImageLabelHelper: fixes LABELs not triggering focus on form elements when they have IMG elements inside

var ImageLabelHelper = Behavior.create({
  initialize : function(){
    if (!(Prototype.Browser.IE || Prototype.Browser.WebKit)) { return; }
    this.form_element = $(this.element.parentNode.getAttribute('for') || this.element.parentNode.attributes['for'].nodeValue);
    if (this.form_element) {
      this.element.observe('click', this.focusElement.bindAsEventListener(this));
    }
  },
  focusElement: function(){
    this.form_element.focus();
  }
});

// ---------------------------------------------------------------------------
// ADD BEHAVIORS : Event.addBehavior block.

Event.addBehavior({
  
  'SELECT' : DisabledOptionsHelper,
  
  'LABEL IMG' : ImageLabelHelper,
	
	'.DHTMLMenu': DHTMLMenu,
	
	'div.SelectList' : SelectList,
	
	'#Font-Sizer' : TextResizer('article-wrapper'),
	
	'#SiteSearch' : SiteSearchToggler,
	
	'.AutoSubmitField' : AutoSubmitField,
	
	'.ReaderTools .print A' : PrintLink(function(){ this.element.up('li').show(); }),
	
	'#comment-pounddown A:click' : function(e){
		var comment_wrapper = $('article-wrapper');
		if (comment_wrapper) {
			var targets = comment_wrapper.childElements();
			if (targets[1]) { 
				targets[1].scrollTo(); // past DIV.Article, to comments or barrier, whichever comes first
				e.stop();
			}
		}
	},
	
	'#featured-book H2' : WidgetHelp({ help_text : "From ACM's expansive collection of unabridged online books." }),
	'#acm-resources H2' : WidgetHelp({ help_text : "From ACM's vast store of information and services." }),
	'#portal H3' : WidgetHelp({ help_text : "Sample ACM's journals, newsletters, and conference proceedings." }),
	'#featured-course H2' : WidgetHelp({ help_text : "From the thousands of free online courses available to ACM members." }),
	'#most-discussed-in-blog-cacm H2' : WidgetHelp({ help_text : "These items have generated the most comments from readers." }),
	'#most-discussed-in-news H2' : WidgetHelp({ help_text : "These items have generated the most comments from readers." }),
	'#most-discussed-in-opinion H2' : WidgetHelp({ help_text : "These items have generated the most comments from readers." }),
	'#conferences-and-events H3' : WidgetHelp({ help_text : "Entries from ACM's calendar of over 170 annual events." }),
	'#top-5-articles H2' : WidgetHelp({ help_text : "Most popular articles in the past 30 days based on views of full-text HTML and PDFs." }),
	'#featured-in-blogs H3' : WidgetHelp({ help_text : "Interesting entries from the blog@CACM and the Blogroll." }),
	'#featured-jobs-wrapper H3' : WidgetHelp({ help_text : "Select openings viewable to ACM Professional and Student Members." }),
	'#related-news-wrapper H3' : WidgetHelp({ help_text : "These stories concern the same general topic as the displayed article." }),
	'#related-resources-wrapper H3' : WidgetHelp({ help_text : "ACM information and services involve the same topic as displayed article." }),
	
	'.Flash' : ClosingFlash
});

// ---------------------------------------------------------------------------
// DOM LOADED : document.observe('dom:loaded') block

document.observe('dom:loaded', function(){
	
	// Attach off site link icons
	new OffSiteLinkalizer('BodyWrapper');

});