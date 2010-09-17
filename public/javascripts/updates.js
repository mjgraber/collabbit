$.noConflict();
jQuery(document).ready(function($){
    
    var commentInitial = 'Add a comment';
    
    function focusComment($frm){
        $txt = $frm.find('.comment-textfield');
        if($txt.val() != commentInitial) return;
        $txt.val('').removeClass('blank');
        $frm.find('.comment-submit').removeClass('hide');
    }
    
    function unfocusComment($frm){
        $txt = $frm.find('.comment-textfield');
        if($txt.val() != '') return;
        $txt.val(commentInitial).addClass('blank');
        $frm.find('.comment-submit').addClass('hide');
    }
    
    $('.new-comment').each(function(){
        var $frm = $(this);
        $(this).find('.comment-textfield').focus(function(){  focusComment($frm) })
                                          .blur(function(){ unfocusComment($frm) });
               
        unfocusComment($(this));
    });
	
	// for filters
	var init = 'Search Keywords';

	if ($('#search').val() == '') {
		$('#search').val(init);
	}
	
	$('#search').focus(function(){
		if($(this).val() == init)
			$(this).val('').removeClass('blank');
	}).blur(function(){
		if($(this).val() == '')
			$(this).val(init).addClass('blank');
	});
	
	$('#filters form').submit(function(){
		if($('#search').val() == init)
			$('#search').val('')
		return true;
	});

	$('#showallgroups').live("click",function(){
		$('.allgroups').removeClass('hide');
		$('#showallgroups').addClass('selected');
		$('#showmygroups').removeClass('selected');
		return false;
	});

	$('#showmygroups').live("click",function(){
		$('.allgroups').addClass('hide');
		$('.allgroups input:checkbox').attr('checked',false);
		$('#showmygroups').addClass('selected');
		$('#showallgroups').removeClass('selected');
		return false;
	});

	// for alert menu
	var upArrow = '&#9650;';
	var downArrow = '&#9660;';

	$('#alert-settings').live("click",function(){
		if ($('#alerts-form').hasClass('hidden')) {
			$('#alerts-form').removeClass('hidden');
			$('#alert-settings .arrow').html(upArrow);
		}
		else {
			$('#alerts-form').addClass('hidden');
			$('#alert-settings .arrow').html(downArrow);
		}
		return false;
	});

	$('#hider').live("click",function(){
		if ($('#new-updates-inner').hasClass('small')) {
			$('#new-updates-inner').removeClass('small');
		} else {
			$('#new-updates-inner').addClass('small');
		}
		return false;
	});

	// for file uploading
	$('#multi').MultiFile({
		
	});
});
