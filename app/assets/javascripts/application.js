// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//
// Required by Blacklight
//= require blacklight/blacklight
//= require_tree .




$(document).ready(function() {

	//Height
  var howhigh = $(".browsable").height();
  $('.browsable').css({ 'height': howhigh + "px" });
  $('.browsable').css({ 'padding': '2em' });


	//Browse the catalog filtering serach
  var jobCount = $('.browsable .in').length;
  $('.list-count').text(jobCount + ' items');
    
  
  $("#search-text").keyup(function () {
     //$(this).addClass('hidden');
  
    var searchTerm = $("#search-text").val();
    var listItem = $('.browsable').children('a');
  
    
    var searchSplit = searchTerm.replace(/ /g, "'):containsi('")
    
      //extends :contains to be case insensitive
  $.extend($.expr[':'], {
  'containsi': function(elem, i, match, array)
  {
    return (elem.textContent || elem.innerText || '').toLowerCase()
    .indexOf((match[3] || "").toLowerCase()) >= 0;
  }
});
    
    
    $(".browsable a").not(":containsi('" + searchSplit + "')").each(function(e)   {
      $(this).addClass('hiding out').removeClass('in');
      setTimeout(function() {
          $('.out').addClass('hidden');
        }, 300);
    });
    
    $(".browsable a:containsi('" + searchSplit + "')").each(function(e) {
      $(this).removeClass('hidden out').addClass('in');
      setTimeout(function() {
          $('.in').removeClass('hiding');
        }, 1);
    });
    
  
    var jobCount = $('.browsable .in').length;
    $('.list-count').text(jobCount + ' items');

    //shows empty state text when no jobs found
    if(jobCount == '0') {
      $('.browsable').addClass('empty');
    }
    else {
      $('.browsable').removeClass('empty');
    }
    
  });
  
                    
});