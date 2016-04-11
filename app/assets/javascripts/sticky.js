$(function(){
    var $can_stick = $('.can-stick');
    $can_stick.width($('.panel-primary').width());
    var offset = $can_stick.offset()['top'];
    $(window).scroll(function(){
       window.scrollY >= offset - 10 ? $can_stick.addClass('sticky') :
                                       $can_stick.removeClass('sticky'); 
    });
});
