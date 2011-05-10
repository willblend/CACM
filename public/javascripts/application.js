// application wide javascript
$(function(){
    // window load
});

$(document).ready(function(){
  $('form label').inFieldLabels();
  Cufon.replace('.articlesList a', {hover: true, ignore: {div: true} });
  
  $('#searchInput, #searchSubmit').focus(function(){
	$(this).parents('#topForm').css('background','url("images/backgrounds/search_box_bg.png") no-repeat 0px -25px');
  });
  $('#searchInput, #searchSubmit').blur(function(){
	$(this).parents('#topForm').css('background','url("images/backgrounds/search_box_bg.png") no-repeat 0px 0px');
  });
  $('#searchSubmit').click(function(){
	$(this).parents('#topForm').css('background','url("images/backgrounds/search_box_bg.png") no-repeat 0px -50px');
  });
  
  $('header nav ul li').hover(
	function() {
		$(this).find('.menuLinks').slideDown('fast');
	}, 
	function() {
		$(this).find('.menuLinks').slideUp('fast');
	}
  );
  
  $('header nav ul li').hover(
	function() {
		$(this).find('.menuText').css('padding','10px 0px 0px 0px');
		$(this).find('.menuText').css('position','relative');
		$(this).find('.menuText').css('border-top','4px solid #a8b2b5');
		$(this).find('.menuText').css('z-index','101');
		$(this).find('.menuText').css('color','#077fba');
	}, 
	function() {
		$(this).find('.menuText').css('padding','14px 0px 0px 0px');
		$(this).find('.menuText').css('position','relative');
		$(this).find('.menuText').css('border-top','0');
		$(this).find('.menuText').css('z-index','101');
		$(this).find('.menuText').css('color','#000');
	}
  );
  
  $('header nav ul li').hover(
	function() {
		$(this).find('.withMenu').css('padding','10px 0px 13px 0px');
	}, 
	function() {
		$(this).find('.withMenu').css('padding','14px 0px 0px 0px');
	}
  );

  //header functionality

  $('.sectionLink a').mouseover(function() {
    var sectionLink, pos;

    if( $('.articlesList:animated').length > 0) {
      return;
    }
    
    $('.sectionLink.selected').removeClass('selected');
    $('#articlesLists').show();

    sectionLink = $(this).closest('.sectionLink');
    pos = sectionLink.prevAll('.sectionLink').length;

    $('.sectionLink.selected').removeClass('selected');
    sectionLink.addClass('selected');
    
    $('.articlesListSelected').removeClass('articlesListSelected').hide();
    $('#articlesLists .articlesList:eq(' + pos + ')').addClass('articlesListSelected').show();
  });
  
  $('#topBox').mouseleave(function() {
    $('#articlesLists').hide();
    $('.sectionLink.selected').removeClass('selected');
  });
  
  $('.issueCover').mouseover(function() {
    $('#articlesLists').hide();
    $('.sectionLink.selected').removeClass('selected');
  });

  $('.articlesList a[data-tooltip]').live('mouseenter', function() {
      var toolTip, tipText;

      $('.toolTip').remove();

      tipText = $(this).attr('data-tooltip');

      toolTip = $('<div />').addClass('toolTip').append(
        $('<p />').addClass('toolTipText').html( $(this).attr('data-tooltip') )
      );

      toolTip.css({ 'top': ($(this).position().top + 5) + 'px' });

      $(this).append(toolTip);
      $(this).css({ 'z-index': '98' });

      toolTip.show();
  });

  $('.articlesList a[data-tooltip]').live('mouseleave', function() {
      $('.toolTip').remove();
      $(this).css({ 'z-index': 1 });
  });

  //end header functionality

});