// custom.jquery.js

$(document).ready(function () {


  function doneResizing() {
    if ($(window).width() < 991) {
      $("#documents.row hr").remove();
      $("#documents.row .record:nth-of-type(even)").after("<hr>");
    }
    else {
      $("#documents.row hr").remove();
      $("#documents.row .record:nth-of-type(3n)").after("<hr>");
    }
  }

  doneResizing();

	var resizeId;
	$(window).resize(function() {
	  clearTimeout(resizeId);
	  resizeId = setTimeout(doneResizing, 200);
	});

  $(document).ajaxSuccess(doneResizing)

});