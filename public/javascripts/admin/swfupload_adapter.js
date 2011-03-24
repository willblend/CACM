var SWFUploadAdapter = Class.create(PageWidget, {
	initialize : function(el, config){
		this.setOptions(config);

		this.node = $(el);
		if (!this.node) { return; }

    this.nodes = {};

    this.nodes['upload_dialog']      = $('upload-dialog');
    this.nodes['queued_files']       = $('queued-files');
    this.nodes['queued_files_list']  = this.nodes['queued_files'].down('ul');
    this.nodes['total_queued_files'] = $('total-queued-files');
    this.nodes['current_file']       = $('current-upload');
    this.nodes['upload_filename']    = $('upload-filename');
    this.nodes['progress_bar']       = $('progress-bar');
		this.nodes['assets_table']       = $('assets-table');

    // bail out if any of the nodes are nill
		if ($H(this.nodes).values().include(null)) { return; }

		this.uploader = this.createSWFUploader();

    // bail out if the user doesn't have flash
		if (!this.uploader) { return; }

		// give the SWFUpload instance a ref to the adapter object for use in the callbacks
		// NOTE: i have a feeling this is a circular ref, so need to verify this in IE for memory leaks
		this.uploader.adapter = this;

		this.current_file_index = 0;

		// move the upload dialog to the body node to avoide positioning problems
		$(document.body).insert(this.nodes['upload_dialog']);

		this.progress_bar = null;
	},
	
	createSWFUploader : function(){
		return new SWFUpload({
			upload_url								: this.CONFIG['upload_url'],
			flash_url									: this.CONFIG['flash_url'],
			file_size_limit						: this.CONFIG['file_size_limit'],
			button_placeholder_id			: this.CONFIG['button_placeholder_id'],
			button_image_url					: this.CONFIG['button_image_url'],
			button_text								: this.CONFIG['button_text'],
			button_text_style					: this.CONFIG['button_text_style'],
			button_width							: this.CONFIG['button_width'],
			button_height							: this.CONFIG['button_height'],
			button_text_top_padding		: this.CONFIG['button_text_top_padding'],
			button_text_left_padding	: this.CONFIG['button_text_left_padding'],
			displayDebugInfo					: this.CONFIG['display_debug_info'],
			debug											: this.CONFIG['debug'],

			swfupload_loaded_handler		 : this.swfuploadLoadedHandler,
			file_dialog_start_handler		 : this.fileDialogStartHandler,
			file_dialog_complete_handler : this.fileDialogCompleteHandler,
			file_queued_handler					 : this.fileQueuedHandler,
			file_queue_error_handler		 : this.fileQueueErrorHandler,
			upload_start_handler				 : this.uploadStartHandler,
			upload_progress_handler			 : this.uploadProgressHandler,
			upload_error_handler				 : this.uploadErrorHandler,
			upload_success_handler			 : this.uploadSuccessHandler,
			upload_complete_handler			 : this.uploadCompleteHandler
		});
	},
	
	addFileToQueue : function(f) {
		var children = this.nodes['queued_files_list'].childElements();
		if (children.length && children[0].hasClassName('Placeholder')) {
			children[0].remove();
		}

		this.nodes['queued_files_list'].insert({
			bottom: new Element('li').update(f.name + " (" + parseInt(f.size, 10).toFilesize() + ")")
		});

	},

	startUpload : function(f) {
		// console.log('startUpload')
		// console.log(arguments);

		var f = this.uploader.getFile(this.current_file_index);
		var stats = this.uploader.getStats();

		this.nodes['total_queued_files'].update(stats.files_queued - 1);
		this.nodes['queued_files_list'].firstDescendant().remove();
		this.nodes['upload_filename'].update(f.name + " (" + parseInt(f.size, 10).toFilesize() + ")");

		// FIXME: commenting this out for now, as the unzip after upload doesn't work (back-end issue)
		// if (/\.zip$/.test(f.name)) {
		//	this.createUnzipForm();
		// } else {
		//	this.uploader.startUpload();
		// }

		this.uploader.startUpload();
	},
	
	createUnzipForm : function() {
		var html = [
			'<div class="unzip-prompt" id="zip-wrapper-' + this.current_file_index + '">',
				'<div class="Field">',
					'<input type="checkbox" class="Checkbox" checked="checked" name="unzip_upload" id="unzip-' + this.current_file_index + '" />',
					'<label for="unzip-' + this.current_file_index + '">Unzip after uploading?</label>',
				'</div>',
				'<input type="button" id="start-' + this.current_file_index + '" value="Start Upload" />',
			'</div>'
		];

		this.nodes['current_file'].insert({ bottom : html.join("\n") });

		this.nodes['progress_bar'].hide();

		$('start-' + this.current_file_index).observe('click', this.checkZipStatusAndStartUpload.bindAsEventListener(this));
	},
	
	checkZipStatusAndStartUpload : function(){
		if ($('unzip-' + this.current_file_index).checked) {
			// FIXME: addFileParam is not working
			this.uploader.addFileParam(this.current_file_index.toString(), 'unzip_asset', 'true');
		}
		$('zip-wrapper-' + this.current_file_index).remove();

		this.nodes['progress_bar'].show();

		this.uploader.startUpload();
	},

	// SWFUpload Callback Functions --------------------------------------------

	swfuploadLoadedHandler : function() {
		// these can only be called after the Flash has loaded
		this.setPostParams(this.adapter.CONFIG['post_data']);
	},

	fileQueuedHandler : function(f) {
		// console.log('fileQueuedHandler');
		// console.log(this.getStats());

		this.adapter.addFileToQueue(f);
	},

	fileQueueErrorHandler : function() {
		// console.log('fileQueueErrorHandler');
		// console.log(arguments);
	},

	fileDialogStartHandler : function() {
		// console.log('dialogStartHandler');
	},

	fileDialogCompleteHandler : function(num_selected, num_queued, total_queued) {
		// console.log('dialogCompleteHandler');
		// console.log(arguments);

		if (num_queued == 0) {
			return;

		} else if (num_queued == 1) {
			this.adapter.nodes['upload_dialog'].removeClassName('queued-files');
			this.adapter.nodes['queued_files'].hide();

		} else {
			this.adapter.nodes['upload_dialog'].addClassName('queued-files');
			this.adapter.nodes['queued_files'].show();
		}

		this.adapter.modal_window = Control.Modal.open(this.adapter.nodes['upload_dialog'], {
			overlayOpacity : 0.75,
			className			 : 'modal',
			closeOnClick	 : false,
			fade					 : false
		});

		this.adapter.startUpload();
	},

	uploadStartHandler : function(f) {
		// console.log('uploadStartHandler');
		// console.log(f);

		if (this.adapter.progress_bar) {
			this.adapter.progress_bar.reset();
		} else {
			this.adapter.progress_bar = new Control.ProgressBar(this.adapter.nodes['progress_bar']);
		}
	},

	uploadProgressHandler : function(f, progress, total) {
		// console.log("uploadProgressHandler: #{progress} of #{total}".interpolate({ progress : progress, total: total}));

	 this.adapter.progress_bar.setProgress(parseInt((progress/total) * 100, 10));
	},

	uploadSuccessHandler : function(f, responseText) {
		// console.log('uploadSuccessHandler');
		// console.log(arguments);

    // insert the new row into the table and highlight it
		var tbody = this.adapter.nodes['assets_table'].down('tbody');
		tbody.insert({ top : responseText });
		new Effect.Highlight(tbody.firstDescendant());

		var children = tbody.childElements();
    // remove the bottom TR if we have more than 50 items listed, or if there is a placeholder in there
    // FIXME: this is kinda fragile w/r/t the colspan and the length checking
		if (children[children.length - 1].down('td').getAttribute('colspan') || children.length > 50) {
			children[children.length - 1].remove();
		}

    // TODO: update the total # of items displayed on the page
	},

	uploadErrorHandler : function() {
    // console.log('uploadErrorHandler');
    // console.log(arguments);

    alert('an error ocurred');
	},

	uploadCompleteHandler : function(f){
//		console.log('uploadCompleteHandler');
//		console.log(arguments);

		this.adapter.current_file_index++;

		// start the next in the queue if there are still files to be uploaded
		if (this.getStats().files_queued > 0) {
			this.adapter.startUpload();
		} else {
			this.adapter.modal_window.close();
		}
	}

});

SWFUploadAdapter.CONFIG = {
	flash_url								 : '/flash/swfupload.swf',
	file_size_limit					 : '64 MB',
	post_data								 : { },
	button_placeholder_id		 : 'swf-upload-button',
	button_image_url				 : '/images/admin/btn.select-file-upload.gif',
	button_text							 : '<span class="swfUploadFont">Upload Assets</span>',
	button_text_style				 : ".swfUploadFont { font-size: 13; font-weight: bold; font-family: Arial; display: block; }",
	button_width						 : 148,
	button_height						 : 25,
	button_text_top_padding	 : 3,
	button_text_left_padding : 4,
	display_debug_info			 : false,
	debug										 : false // enable this to display swfupload's debugging output!
};
