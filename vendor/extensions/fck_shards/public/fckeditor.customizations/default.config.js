// Generic Radiant FCK config file for all FCK instances within the Radiant Admin UI.
// This file gets included, and overriden/extended via the RadiantFCK object.

// custom toolbars
FCKConfig.ToolbarSets["Standard"] = [
	['Source','ShowBlocks', 'FitWindow'],
	['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
	['Image','Flash','Table','Rule','SpecialChar'],
	['Link','Unlink','Anchor'],
	'/',
	['Cut','Copy','Paste','PasteText','PasteWord'],
	['Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript'],
	['OrderedList','UnorderedList','-','Outdent','Indent','Blockquote'],
	['JustifyLeft','JustifyCenter','JustifyRight','JustifyFull'],
	'/',
	['Templates','Style','TextColor','BGColor']
];

FCKConfig.ToolbarSets["Inline"] = [
  ['Source','ShowBlocks'],
	['Undo','Redo','-','RemoveFormat'],
	['Cut','Copy','Paste','PasteText','PasteWord'],
	['Link','Unlink'],
	['Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript'],
	['SpecialChar']
];

// Used for article branding: simply the first row of the Standard toolbar

FCKConfig.ToolbarSets["Branding"] = [
['Source','ShowBlocks', 'FitWindow'],
['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
['Image','Flash','Table','Rule','SpecialChar'],
['Link','Unlink','Anchor']
];

// custom styles are added via StylesXmlPath, so this is not used.
FCKConfig.CustomStyles = { };

// set the DOCTYPE to be XHTML
FCKConfig.DocType = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">';

// keep the HTML structure
FCKConfig.CleanWordKeepsStructure = true;

// disable standard FCK image/file upload tabs in image/link dialogs
FCKConfig.ImageUpload = false;
FCKConfig.LinkUpload = false;

// disable standard "Browse Server" button
FCKConfig.LinkBrowser = false;

// don't allow the mini templates to replace all of the content in the editor
FCKConfig.TemplateReplaceAll = false;
FCKConfig.TemplateReplaceCheckbox = false;

// shows where the block elements boundaries are in the editor
FCKConfig.StartupShowBlocks = false;

FCKConfig.BodyId = 'FCK-editor';
FCKConfig.BodyClass = '';

// tags that FCK will leave alone. separate tags with a pipe character ("|")
FCKConfig.ProtectedTags = '';

FCKConfig.FlashBrowserURL = '/admin/assets/all.fck';
