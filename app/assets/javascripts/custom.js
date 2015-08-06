$(document).ready(function() {
  
  
    //Height for Browsable
    var howhigh = $(".browsable").height();
    $('.browsable').css({ 'min-height': howhigh + "px" });
    $('.browsable').css({ 'padding': '2em' });


    //Filter for Browsable
    var jobCount = $('.browsable .in').length;
    $('.list-count').text(jobCount + ' items');
      
    
    $("#browse-search").keyup(function () {
       //$(this).addClass('hidden');
    
      var searchTerm = $("#browse-search").val();
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