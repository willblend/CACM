function preview(button) {
  form = button.form;
  oldtarget = form.target;

  if (RadiantFCK){
    RadiantFCK.instances.each(function(b) {
      var api = FCKeditorAPI.GetInstance(b.element.id);
      if (api) {
        api.UpdateLinkedField();
      }
    });
  }


  location.hash = 'show-preview';

  form.target = 'page-preview';
  $('preview-busy').show();

  var req = new Ajax.Request('/admin/preview', {
    parameters: form.serialize(),
    onSuccess: function(transport) {
      previewWindow = window.open('', 'preview_page', 'location=no,toolbar=no,scrollbars=yes,resizable=yes', true);
      previewWindow.document.write(transport.responseText);
      previewWindow.document.close();
    },
    onComplete: function(transport) { 
      $('preview-busy').hide();
    }
  });

  form.target = oldtarget;

  return false;
}