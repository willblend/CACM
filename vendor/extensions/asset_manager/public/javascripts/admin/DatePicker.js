// add new methods to Date.prototype
(function(){

	Date.MONTH_NAMES = $w("January February March April May June July August September October November December");
	Date.DAY_NAMES   = $w("Sunday Monday Tuesday Wednesday Thursday Friday Saturday");

	// -------------------------------------------------------------------------

	var date_methods = {
		getDaysInMonth : function() {
		  return [31, (this.isLeap() ? 29 : 28), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][this.getMonth()];
		},

		stripTime : function() {
			this.setHours(0);
			this.setMinutes(0);
			this.setSeconds(0);
			this.setMilliseconds(0);
			return this;
		},

		isSameDateAs : function(date) {
		  return (this.getFullYear()  == date.getFullYear() 
		       && this.getMonth()     == date.getMonth()
		       && this.getDate()      == date.getDate ()
			);
		},
		
		isLeap : function() {
		  return 1 == new Date(this.getFullYear(), 1, 29).getMonth();
		},

		previousMonth : function() {
			if (this.getMonth() == 0) {
				this.setYear(this.getFullYear() - 1);
				this.setMonth(11);

			} else {
				this.setMonth(this.getMonth() - 1);
			}

			return this;
		},

		previousDay : function() {
			this.setMilliseconds(-1000 * 60 * 60 * 24);
			return this;
		},

		// adapted from http://www.codeproject.com/jscript/dateformat.asp
		format : function(f) {
			if (!this.valueOf()) return '&nbsp;';
			var d = this;

			return f.gsub(/(yyyy|mmmm|mmm|mm|dddd|ddd|dd|hh|nn|ss|a\/p)/i,
				function(match) {
					switch (match[1].toLowerCase()) {
						case 'yyyy': return d.getFullYear();
						case 'mmmm': return Date.MONTH_NAMES[d.getMonth()];
						case 'mmm':  return Date.MONTH_NAMES[d.getMonth()].substr(0, 3);
						case 'mm':   return (d.getMonth() + 1).toPaddedString(2);
						case 'dddd': return Date.DAY_NAMES[d.getDay()];
						case 'ddd':  return Date.DAY_NAMES[d.getDay()].substr(0, 3);
						case 'dd':   return d.getDate().toPaddedString(2);
						case 'hh':   return ((h = d.getHours() % 12) ? h : 12).toPaddedString(2);
						case 'nn':   return d.getMinutes().toPaddedString(2);
						case 'ss':   return d.getSeconds().toPaddedString(2);
						case 'a/p':  return d.getHours() < 12 ? 'a' : 'p';
					}
				}
			);
		}

	};

	for (var m in date_methods) {
		if (!Date.prototype[m]) { Date.prototype[m] = date_methods[m]; }
	}

	// -------------------------------------------------------------------------

	var array_methods = {
		/* Finds the index of the first occurence of item in the array, or -1 if not found */
		indexOf : function(item) {
			for (var i = 0; i < this.length; i++) {
				if (this[i] == item) {
					return i;
				}
			}
			return -1;
		},

		/* Returns an array of items judged 'true' by the passed in test function */
		filter : function(test) {
			var matches = [];
			for (var i = 0; i < this.length; i++) {
				if (test(this[i])) {
					matches[matches.length] = this[i];
				}
			}
			return matches;
		}

	};

	for (var m in array_methods) {
		if (!Array.prototype[m]) { Array.prototype[m] = array_methods[m]; }
	}

	/* 'Magic' date parsing, by Simon Willison (6th October 2003)
	 *  http://simon.incutio.com/archive/2003/10/06/betterDateInput
   */
	if (!Date.smartParse) {
		Date.smartParse = function(s) {

			var monthNames = "January February March April May June July August September October November December".split(" ");
			var weekdayNames = "Sunday Monday Tuesday Wednesday Thursday Friday Saturday".split(" ");

			/* Takes a string, returns the index of the month matching that string, throws
			   an error if 0 or more than 1 matches
			*/
			function parseMonth(month) {
				var matches = monthNames.filter(function(item) { 
					return new RegExp("^" + month, "i").test(item);
				});
				if (matches.length == 0) {
					throw new Error("Invalid month string");
				}
				if (matches.length > 1) {
					throw new Error("Ambiguous month");
				}
				return monthNames.indexOf(matches[0]);
			}

			/* Same as parseMonth but for days of the week */
			function parseWeekday(weekday) {
				var matches = weekdayNames.filter(function(item) {
					return new RegExp("^" + weekday, "i").test(item);
				});
				if (matches.length == 0) {
					throw new Error("Invalid day string");
				}
				if (matches.length > 1) {
					throw new Error("Ambiguous weekday");
				}
				return weekdayNames.indexOf(matches[0]);
			}


			/* Array of objects, each has 're', a regular expression and 'handler', a 
			   function for creating a date from something that matches the regular 
			   expression. Handlers may throw errors if string is unparseable. 
			*/
			var dateParsePatterns = [
					// Today
					{ 	re: /^tod/i,
							handler: function() { 
								return new Date();
							} 
					},
					// Tomorrow
					{ 	re: /^tom/i,
							handler: function() {
								var d = new Date(); 
								d.setDate(d.getDate() + 1); 
								return d;
							}
					},
					// Yesterday
					{ 	re: /^yes/i,
							handler: function() {
								var d = new Date();
								d.setDate(d.getDate() - 1);
								return d;
							}
					},
					// 4th
					{ 	re: /^(\d{1,2})(st|nd|rd|th)?$/i, 
							handler: function(bits) {
								var d = new Date();
								d.setDate(parseInt(bits[1], 10));
								return d;
							}
					},
					// 4th Jan
					{ 	re: /^(\d{1,2})(?:st|nd|rd|th)? (\w+)$/i, 
							handler: function(bits) {
								var d = new Date();
								d.setDate(parseInt(bits[1], 10));
								d.setMonth(parseMonth(bits[2]));
								return d;
							}
					},
					// 4th Jan 2003
					{ 	re: /^(\d{1,2})(?:st|nd|rd|th)? (\w+),? (\d{4})$/i,
							handler: function(bits) {
								var d = new Date();
								d.setDate(parseInt(bits[1], 10));
								d.setMonth(parseMonth(bits[2]));
								d.setYear(bits[3]);
								return d;
							}
					},
					// Jan 4th
					{ 	re: /^(\w+) (\d{1,2})(?:st|nd|rd|th)?$/i, 
							handler: function(bits) {
								var d = new Date();
								d.setDate(parseInt(bits[2], 10));
								d.setMonth(parseMonth(bits[1]));
								return d;
							}
					},
					// Jan 4th 2003
					{ 	re: /^(\w+) (\d{1,2})(?:st|nd|rd|th)?,? (\d{4})$/i,
							handler: function(bits) {
								var d = new Date();
								d.setDate(parseInt(bits[2], 10));
								d.setMonth(parseMonth(bits[1]));
								d.setYear(bits[3]);
								return d;
							}
					},
					// next Tuesday - this is suspect due to weird meaning of "next"
					{ 	re: /^next (\w+)$/i,
							handler: function(bits) {
								var d = new Date();
								var day = d.getDay();
								var newDay = parseWeekday(bits[1]);
								var addDays = newDay - day;
								if (newDay <= day) {
									addDays += 7;
								}
								d.setDate(d.getDate() + addDays);
								return d;
							}
					},
					// last Tuesday
					{ 	re: /^last (\w+)$/i,
							handler: function(bits) {
								throw new Error("Not yet implemented");
							}
					},
					// mm/dd/yyyy (American style)
					{ 	re: /(\d{1,2})\/(\d{1,2})\/(\d{4})/,
							handler: function(bits) {
								var d = new Date();
								d.setFullYear(bits[3]);
								d.setDate(parseInt(bits[2], 10));
								d.setMonth(parseInt(bits[1], 10) - 1); // Because months indexed from 0
								return d;
							}
					},
					// mm/dd/yy (American style)
					{ 	re: /(\d{1,2})\/(\d{1,2})\/(\d{2})/,
							handler: function(bits) {
								var d = new Date();
								var y = parseInt(new Date().getFullYear().toString().substring(2,4), 10);
								d.setFullYear( ((bits[3] < (y + 30)) ? "20" : "19") + bits[3]);
								d.setDate(parseInt(bits[2], 10));
								d.setMonth(parseInt(bits[1], 10) - 1); // Because months indexed from 0
								return d;
							}
					},
					// mm/dd (American style)
					{ 	re: /(\d{1,2})\/(\d{1,2})/,
							handler: function(bits) {
								var d = new Date();
								d.setDate(parseInt(bits[2], 10));
								d.setMonth(parseInt(bits[1], 10) - 1); // Because months indexed from 0
								return d;
							}
					},
					// yyyy-mm-dd (ISO style)
					{ 	re: /(\d{4})-(\d{1,2})-(\d{1,2})/,
							handler: function(bits) {
								var d = new Date();
								d.setFullYear(parseInt(bits[1], 10));
								d.setDate(parseInt(bits[3], 10));
								d.setMonth(parseInt(bits[2], 10) - 1);
								return d;
							}
					}
			];

			for (var i = 0; i < dateParsePatterns.length; i++) {
				var re = dateParsePatterns[i].re;
				var handler = dateParsePatterns[i].handler;
				var bits = re.exec(s);
				if (bits) {
						return handler(bits);
				}
			}
			throw new Error("Invalid date string");
		};
	}

})();


// ===========================================================================


var DatePicker = Behavior.create(PageWidget, {
	nodes : { // holds various DOM nodes for easy reference
		widget         : null,
		table          : null,
		nav            : null,
		nav_prev       : null,
		nav_next       : null,
		nav_prev_month : null,
		nav_next_month : null,
		nav_prev_year  : null,
		nav_next_year  : null,
		helper_text    : null
	},
	body_node : null, // DOM node: document BODY

	options : null, // options for DatePicker instance, copied from CONFIG
	current_month_date : null, // Date of visible calendar

	hide_timeout : null,


	/* -- BEGIN: PUBLIC METHODS --------------------------------------------- */

	// takes an INPUT and associates the new DatePicker to it
	initialize : function(options) {
		// sanity check
		if (this.element.type != 'text' || (typeof(this.element.DatePicker) != 'undefined') ) { return; }

		// add a reference to the INPUT to access the widget from the DOM
		this.element.DatePicker = this;

		// prime the nodes object to hold our node refs
		this.nodes = Object.clone(this.nodes);

		// set the options
		this.setOptions(options);

		// clean up dates if needed
		this._checkAndFixDateBoundaries();

		// attach event handlers
		this.element.observe('focus', this.inputFocusHandler.bindAsEventListener(this));
		this.element.observe('blur',  this.inputBlurHandler.bindAsEventListener(this));

		this.element.observe('keyup', this.inputFocusHandler.bindAsEventListener(this));
		this.element.observe('click', this.inputFocusHandler.bindAsEventListener(this));

		var next_node = this.element.next();

		if (this.CONFIG['show_helper_text']) {
			this.nodes['helper_text'] = this._buildHelperTextMarkup();

			if (!this.element.value.empty() && !this.element.value.blank()) {
				try { this._updateHelperText(Date.smartParse(this.element.value)); }
				catch(e) { }
			} else {
				this.nodes['helper_text'].hide();
			}

			// NOTE: this may have to change depending on how the markup/style is for the FORM
			this.element.insert({ 'after' : this.nodes['helper_text'] });
			// this.element.up().insert({ 'bottom' : this.nodes['helper_text'] });
		}

		// store the body for later use
		// FIXME: replace with document.body?
		this.body_node = Element.extend(document.getElementsByTagName('body')[0]);

		// pre-bind the event handler so we can remove it later
		this.documentMousedownHandlerListener = this.documentMousedownHandler.bindAsEventListener(this);

	}, // END: initialize()

	show : function(open_date) {
		// close the last DatePicker that was open
		if (this.constructor.last_open) { this.constructor.last_open.hide(); }

		// create the calendar and attach it into the DOM, keeping a reference of it for future use
		if (!this.nodes['widget']) {
			this.nodes['widget'] = this._buildCalendarWidget(open_date);
			this._positionWidget();
			this.body_node.appendChild(this.nodes['widget']);
		}

		// start listening for our widget hide event
		this.body_node.observe('mousedown', this.documentMousedownHandlerListener);

		// remember this DatePicker
		this.constructor.last_open = this;
	},

	hide : function() {
		if (!this.nodes['widget']) { return; }

		// remove the widget from the document
		this.nodes['widget'].remove();
		this.nodes['widget'] = null;

		// stop listening for our widget hide event
		this.body_node.stopObserving('mousedown', this.documentMousedownHandlerListener);

		// clear the class var
		this.constructor.last_open = null;
	},

	gotoMonth : function(date) {
		// only go to the month if out of bounds browsing is enabled or the month has 'active' days
		if (this._isMonthBrowsable(date)) {

			// remove old month table, insert new table
			this.nodes['table'].remove();
			this.nodes['table'] = Element.extend(this.nodes['widget'].appendChild(this._buildMonthMarkup(date)));

			//  update the nav to reflect new navigation possiblities
			this._updateNavMarkup();
		}
	},

	highlightDay : function(date) {
		if (this.last_open_cell) {
			this.last_open_cell.removeClassName('Selected');
		}

		var cell = this._findCell(date);
		if (cell) { cell.addClassName('Selected'); }

		this.last_open_cell = cell;
	},

	/* ----------------------------------------------- END: PUBLIC METHODS -- */


	/* -- BEGIN: PRIVATE METHODS -------------------------------------------- */

	// ensure that the start, end, and open dates are sane
	_checkAndFixDateBoundaries : function() {
		// problem: missing open date
		// solution: set the open date to today
		if (this.CONFIG.open_date == null) {
			// console.log(this.node.name + ': open date missing; setting to today');
			this.CONFIG.open_date = new Date();
		}

		// problem: end date before start date
		// solution: remove end date
		if (this.CONFIG.start_date && this.CONFIG.end_date  && (this.CONFIG.start_date > this.CONFIG.end_date)) {
			// console.log(this.element.name + ': end date invalid; removing');
			this.CONFIG.end_date = null;
		}

		// problem: open date before start date or after end date
		// solution: reset open date to start date in both cases
		if ( (this.CONFIG.start_date && this.CONFIG.open_date && (this.CONFIG.open_date < this.CONFIG.start_date))
			|| (this.CONFIG.end_date   && this.CONFIG.open_date && (this.CONFIG.open_date > this.CONFIG.end_date))
		) {
			// console.log(this.element.name + ': open date invalid; setting to start date');
			this.CONFIG.open_date = new Date(this.CONFIG.start_date);
		}
	},

	_buildCalendarWidget : function(open_date) {
		var widget = new Element('DIV', { 'class' : this.CONFIG['class_name_widget'], 'id' : this.CONFIG['id_prefix'] + "_" + this.element.identify() });

		widget.observe('click', this.widgetClickHandler.bindAsEventListener(this));

		this.nodes['nav']   = widget.appendChild(this._buildNavMarkup());
		this.nodes['table'] = widget.appendChild(this._buildMonthMarkup(open_date));

		this._updateNavMarkup();

		return widget;
	},

	_buildNavMarkup : function() {
		var nav = new Element('DIV', { 'class' : this.CONFIG['class_name_nav'] });

		var nav_prev = new Element('DIV', { 'class' : this.CONFIG['class_name_nav_prev'] });

		var nav_next = new Element('DIV', { 'class' : this.CONFIG['class_name_nav_next'] });

		var nav_prev_y = new Element('SPAN', { 'class' : this.CONFIG['class_name_nav_prev_year'], 'title' : this.CONFIG['text_prev_year'] }).update('\u00AB');
		nav_prev_y.observe('click', this.navClickHandler.bindAsEventListener(this, "PREV_YEAR"));

		var nav_prev_m = new Element('SPAN', { 'class' : this.CONFIG['class_name_nav_prev_month'], 'title' : this.CONFIG['text_prev_month'] }).update('\u2039');
		nav_prev_m.observe('click', this.navClickHandler.bindAsEventListener(this, "PREV_MONTH"));

		var nav_next_m = new Element('SPAN', { 'class' : this.CONFIG['class_name_nav_next_month'], 'title' : this.CONFIG['text_next_month'] }).update('\u203A');
		nav_next_m.observe('click', this.navClickHandler.bindAsEventListener(this, "NEXT_MONTH"));

		var nav_next_y = new Element('SPAN', { 'class' : this.CONFIG['class_name_nav_next_year'], 'title' : this.CONFIG['text_next_year'] }).update('\u00BB');
		nav_next_y.observe('click', this.navClickHandler.bindAsEventListener(this, "NEXT_YEAR"));

		this.nodes['nav_prev_year'] = nav_prev.appendChild(nav_prev_y);
		nav_prev.appendChild(document.createTextNode(' '));
		this.nodes['nav_prev_month'] = nav_prev.appendChild(nav_prev_m);

		this.nodes['nav_next_month'] = nav_next.appendChild(nav_next_m);
		nav_next.appendChild(document.createTextNode(' '));
		this.nodes['nav_next_year'] = nav_next.appendChild(nav_next_y);

		this.nodes['nav_prev'] = nav.appendChild(nav_prev);
		this.nodes['nav_next'] = nav.appendChild(nav_next);

		return nav;
	},

	_updateNavMarkup : function() {
		// current_month_date is first day of month
		var new_date = new Date(this.current_month_date);

		if (this._isMonthBrowsable(new Date(new_date.setFullYear(new_date.getFullYear() - 1)))) {
			this.nodes['nav_prev_year'].addClassName('Link');
		} else {
			this.nodes['nav_prev_year'].removeClassName('Link');
		}
		this.nodes['nav_prev_year'].title = this._getMonthAndYearString(new_date);

		new_date = new Date(this.current_month_date);

		// check for one day earlier than the first day of the current month
		if (this._isMonthBrowsable(new_date.previousDay())) {
			this.nodes['nav_prev_month'].addClassName('Link');
		} else {
			this.nodes['nav_prev_month'].removeClassName('Link');
		}
		this.nodes['nav_prev_month'].title = this._getMonthAndYearString(new_date);

		new_date = new Date(this.current_month_date);

		// check for first day of next month
		if (this._isMonthBrowsable(new Date(new_date.setMonth(this.current_month_date.getMonth() + 1)))) {
			this.nodes['nav_next_month'].addClassName('Link');
		} else {
			this.nodes['nav_next_month'].removeClassName('Link');
		}
		this.nodes['nav_next_month'].title = this._getMonthAndYearString(new_date);

		new_date = new Date(this.current_month_date);

		if (this._isMonthBrowsable(new Date(new_date.setYear(this.current_month_date.getFullYear() + 1)))) {
			this.nodes['nav_next_year'].addClassName('Link');
		} else {
			this.nodes['nav_next_year'].removeClassName('Link');
		}
		this.nodes['nav_next_year'].title = this._getMonthAndYearString(new_date);

	},

	_getMonthAndYearString : function(date) {
		return date.format('MMMM YYYY');
	},

	_buildMonthMarkup : function(date) {
		// set the to the first day of the month for calculations
		var month_date = date || new Date(this.CONFIG.open_date);
		month_date.setDate(1);

		// store the current month, to be used for navigation
		this.current_month_date = month_date;

		// create the calendar table
		var table = new Element("table", { 'class' : this.CONFIG['class_name_table'] });

		// month name goes in CAPTION element of the TABLE
		var caption = new Element("caption").update(this.CONFIG['text_month'][month_date.getMonth()] + " " + month_date.getFullYear());

		table.appendChild(caption);

		// create day name col headers in THEAD
		var thead = new Element("thead");
		var tr = new Element("tr");
		this.CONFIG['text_day'].each(function(day){
			var th = new Element("th", { 'title' : day }).update(day.charAt(0));
			tr.appendChild(th);
		}.bind(this));
		thead.appendChild(tr);
		table.appendChild(thead);

		// the TBODY holds the day cells
		var tbody = new Element("tbody");

		// do some day math to figure out which days we'll be showing
		var td_day = 0 - month_date.getDay();
		var days_in_month = month_date.getDaysInMonth();
		var max_days = Math.ceil((month_date.getDaysInMonth() + month_date.getDay()) / 7);

		// create the calendar rows/cells
		for (var i=0; i < max_days; i++) {
			tr = new Element("tr");

			for (var j=0; j < 7; j++) {
				td_day++;

				var td = new Element("td");

				// create a date object for each cell
				td.date = (new Date(month_date.getFullYear(), month_date.getMonth(), td_day)).stripTime();

				// be nice and set the title of the TD to a formatted date string
				td.title = this.CONFIG['text_month'][td.date.getMonth()] + " " + td.date.getDate() + ", " + td.date.getFullYear();

				// if day is in current month
				if ( (td_day >= 1) && (td_day <= days_in_month) ) {

					// output the number into the TD
					td.appendChild(document.createTextNode(td_day));

					// add event handlers if the cell's date is within our bounds
					if (this._isDateWithinBounds(td.date)) {
						td.observe("mousedown", this.cellClickHandler.bindAsEventListener(this, td.date));
						td.observe("mouseover", this.cellMouseoverHandler.bindAsEventListener(this));
						td.observe("mouseout",  this.cellMouseoutHandler.bindAsEventListener(this));

					// otherwise, add a disabled class to the cell
					} else {
						td.addClassName('Disabled');
					}

					// check for today and add a class to denote it
					if ( td.date.isSameDateAs(new Date()) ) {
						td.addClassName('Today');
					}

				// else day is before or after current month
				} else {
					td.appendChild(document.createTextNode(td.date.getDate()));
					td.addClassName('OtherMonth');
				}

				tr.appendChild(td);
			}
			tbody.appendChild(tr);
		}
		table.appendChild(tbody);

		return table;
	},

	_isDateWithinBounds : function(date) {
		// NOTE: this logic is complicated, so i did it long-hand
		// the current day's date is in-bounds if:
		// 1) start/end date does not exist ...OR...
		// 2) start/end date exists and current day's date is after/before it
		var after_start_date = !this.CONFIG.start_date || ( this.CONFIG.start_date && (date >= this.CONFIG.start_date.stripTime()) );
		var before_end_date  = !this.CONFIG.end_date   || ( this.CONFIG.end_date   && (date <= this.CONFIG.end_date.stripTime())   );

		return (after_start_date && before_end_date);
	},

	_isMonthBrowsable : function(date) {
		// variation on _isDateWithinBounds, except that we set the start/end date 
		// to the first of the month to ease checking if they are in the month
		// FIXME: could probably be done a different way
		var after_start_date = !this.CONFIG.start_date || ( new Date(this.CONFIG.start_date).setDate(1) && (date >= new Date(this.CONFIG.start_date.stripTime()).setDate(1)) );
		var before_end_date  = !this.CONFIG.end_date   || ( new Date(this.CONFIG.end_date).setDate(1)   && (date <= new Date(this.CONFIG.end_date.stripTime()).setDate(1))   );

		return this.CONFIG.out_of_bounds_browsing || (after_start_date && before_end_date);
	},

	_positionWidget : function() {
		// var position = {
		// 	setHeight : false,
		// 	setWidth : false
		// };
		var position = { };

		var offset = this.element.cumulativeOffset();

		switch (this.CONFIG.calendar_anchor_position) {
			case "RIGHT":
			// position.offsetLeft = this.element.offsetWidth + 4; // due to border of input
				position = {
					'top'  : (offset[1]) + "px",
					'left' : (offset[0] +  + this.element.offsetWidth + 4) + "px"
				};

				break;

			case "BOTTOM":
				// position.offsetTop = this.element.offsetHeight;
				position = {
					'top'  : (offset[1] + this.element.offsetHeight) + "px",
					'left' : (offset[0]) + "px"
				};

				break;
		}

//		this.nodes['widget'].clonePosition(this.node, position);
//		Position.clone(this.node, this.nodes['widget'], position);

		this.nodes['widget'].setStyle(position);

	},

	// clear vars for next showing of calendar
	_clearCalendar : function() {
		this.current_month_date = null;
	},

	_buildHelperTextMarkup : function() {
		return new Element('div', { 'class' : this.CONFIG['class_name_helper_text'] + " FieldValue" });
	},

	_updateHelperText : function(date) {
		if (!this.CONFIG['show_helper_text']) return;
		
		if (date) {
			this.nodes['helper_text'].update(date.format(this.CONFIG['helper_text_date_format']));
		} else {
			this.nodes['helper_text'].update("");
		}

		if (!this.nodes['helper_text'].innerHTML.blank()) {
			this.nodes['helper_text'].show();
		}
	},

	_findCell : function(date) {
		if (!date) { return; }
		return $A(this.nodes['table'].getElementsByTagName('td')).find(function(td){
			return date.isSameDateAs(td.date);
		});
	},

	/* ----------------------------------------------END: PRIVATE METHODS --  */


	/* -- BEGIN: EVENT HANDLERS --------------------------------------------- */

	widgetClickHandler : function(e) {
		e.stop();
	},

	inputFocusHandler : function(e) {
		var open_date = null;

		clearTimeout(this.hide_timeout);

		// bail out of the widget is already open
		if (this.nodes['widget']) {
			if (this.element.value.blank()) { return; }

			try {
				open_date = Date.smartParse(this.element.value);
			} catch(e) {
				return;
			}

			var highlight_date = new Date(open_date);

			this.gotoMonth(open_date);

			this.highlightDay(highlight_date);

			return;
		}

		// parse date that exists inside input and use that as open date
		// if bad, fall back to this.CONFIG.open_date
		try {
			open_date = Date.smartParse(this.element.value) || new Date(this.CONFIG.open_date);
		} catch (e) {
			open_date = new Date(this.CONFIG.open_date);
		}

		var highlight_date = new Date(open_date);

		this.show(open_date);

		if (!highlight_date.isSameDateAs(new Date()) || !this.element.value.blank() ) {
			this.highlightDay(highlight_date);
		}

	},

	inputBlurHandler : function(e) {
		try {
			var date = Date.smartParse(this.element.value);
			this.element.value = date.format(this.CONFIG['field_date_format']);
			this._updateHelperText(date);
		} catch (e) {
			this.element.value = "";
			this._updateHelperText();
		}

		this.hide_timeout = setTimeout(function() {
			this.hide();	
		}.bind(this), 100);
		
	},

	cellClickHandler : function(e, td_date) {
		clearTimeout(this.hide_timeout);

		e.stop();

		// put the clicked date into the INPUT field
		this.element.value = td_date.format(this.CONFIG['field_date_format']);

		this._updateHelperText(td_date);

		this.hide();
	},

	cellMouseoverHandler : function(e) {
		e.element().addClassName('Hover');
	},

	cellMouseoutHandler : function(e) {
		var node = Event.element(e);

		// for safari, which likes triggering events on text nodes
		if (node.nodeType != 1) {
			node = Element.extend(node.parentNode);
		}

		node.removeClassName('Hover');
	},

	navClickHandler : function(e, dir) {
		clearTimeout(this.hide_timeout);

		Event.stop(e);

		var new_date = new Date(this.current_month_date);

		switch (dir) {
			case "PREV_YEAR":  new_date.setYear(this.current_month_date.getFullYear() - 1); break;
			case "PREV_MONTH": new_date.previousMonth(); break;
			case "NEXT_MONTH": new_date.setMonth(this.current_month_date.getMonth() + 1); break;
			case "NEXT_YEAR":  new_date.setYear(this.current_month_date.getFullYear() + 1); break;
			default: return;
		}

		this.gotoMonth(new_date.stripTime());
	},
	
	documentMousedownHandler : function(e) {
		var el = e.element();

		if ( (el == this.nodes['widget']) || (el.up("#" + this.nodes['widget'].id)) ) {
			clearTimeout(this.hide_timeout);
			e.stop();
		}
	}

	/* ----------------------------------------------- END: EVENT HANDLERS -- */

});

DatePicker.CONFIG = {
	id_prefix : "DatePicker",

	field_date_format : "MM/DD/YYYY",

	start_date : null,
	end_date   : null,
	open_date  : null,

	calendar_anchor_position : "RIGHT",

	out_of_bounds_browsing : false,

	show_helper_text : true,
	helper_text_date_format : "DDDD, MMMM DD, YYYY",

	text_month       : $w("January February March April May June July August September October November December"),
	text_day         : $w("Sunday Monday Tuesday Wednesday Thursday Friday Saturday"),
	text_prev_month  : "Previous Month",
	text_next_month  : "Next Month",
	text_prev_year   : "Previous Year",
	text_next_year   : "Next Year",

	class_name_widget         : "CalendarWidget",
	class_name_header         : "CalendarHeader",
	class_name_month          : "CalendarMonth",
	class_name_nav            : "CalendarNav",
	class_name_nav_prev       : "CalendarNavPrev",
	class_name_nav_next       : "CalendarNavNext",
	class_name_nav_prev_month : "CalendarNavPrevMonth",
	class_name_nav_next_month : "CalendarNavNextMonth",
	class_name_nav_prev_year  : "CalendarNavPrevYear",
	class_name_nav_next_year  : "CalendarNavNextYear",
	class_name_table          : "CalendarTable",
	class_name_day            : "CalendarDay",
	class_name_helper_text    : "CalendarHelperText"
};

DatePicker.last_open = null; // object ref to last open DatePicker. used when focus is achieved via keyboard


// ---------------------------------------------------------------------------


var DatePickerStatic = Behavior.create(DatePicker, {
	initialize : function(options) {
		// sanity check
		if (this.element.type != 'text' || (typeof(this.element.DatePicker) != 'undefined') ) { return; }

		this.element.DatePicker = this;

		// prime the nodes object to hold our node refs
		this.nodes = Object.clone(this.nodes);

		// set the options and 
		this.setOptions(options);

		// clean up dates if needed
		this._checkAndFixDateBoundaries();

		// store the body for later use
		// FIXME: replace with document.body?
		this.body_node = Element.extend(document.getElementsByTagName('body')[0]);

		// create the calendar and attach it into the DOM, keeping a reference of it for future use
		this.nodes['widget'] = this._buildCalendarWidget(Date.smartParse(this.element.value));

		var next_node = this.element.next();

		if (next_node) {
			this.element.insertBefore(this.nodes['widget'], next_node);
		
		} else {
			this.element.up().appendChild(this.nodes['widget']);
		}

		if (this.CONFIG['show_helper_text']) {
			this.nodes['helper_text'] = this._buildHelperTextMarkup();

			if (!this.element.value.empty() && !this.element.value.blank()) {
				try { this._updateHelperText(Date.smartParse(this.element.value)); }
				catch(e) { }
			}

//		this.element.insert({ after: this.nodes['widget'] });
//		this.element.insert({ after: this.nodes['helper_text'] });

			if (next_node) {
				this.element.insertBefore(this.nodes['helper_text'], next_node);
			
			} else {
				this.element.up().appendChild(this.nodes['helper_text']);
			}
		}

		this.nodes['widget'].setStyle({ 'position' : 'static' });

		this.highlightDay(Date.smartParse(this.element.value));

		this.element.hide();

		delete this.inputFocusHandler;
	},

	show : Prototype.emptyFunction,

	hide : Prototype.emptyFunction,

	last_open_cell : null,

	cellClickHandler : function(e, td_date) {
		Event.stop(e);

		// put the clicked date into the INPUT field
		this.element.value = td_date.format(this.CONFIG['field_date_format']);

		var cell = Event.element(e);
		if (cell.nodeType != 1) {
			cell = Element.extend(cell.parentNode);
		}

		if (this.last_open_cell) {
			this.last_open_cell.removeClassName('Selected');
		}

		cell.addClassName('Selected');

		this.last_open_cell = cell;

		this._updateHelperText(td_date);
	}

});

DatePickerStatic.CONFIG = Object.clone(DatePicker.CONFIG);


// ---------------------------------------------------------------------------


Event.addBehavior({
	'INPUT.DatePicker' : DatePicker,
	'INPUT.DatePickerStatic' : DatePickerStatic
});
