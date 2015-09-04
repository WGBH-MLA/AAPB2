// custom.jquery.js

$(document).ready(function () {

	//check window size and inserts an <hr> appropriately
	if ($(window).width() < 991) {
		$("#documents.row .record:nth-of-type(even)").after("<hr>");
	}
	else {
		$("hr").remove();
		$("#documents.row .record:nth-of-type(3n)").after("<hr>");
	}

	//Same thing as about but accounts for window resize
	var resizeId;
	$(window).resize(function() {
	  clearTimeout(resizeId);
	  resizeId = setTimeout(doneResizing, 200);
	});

	function doneResizing() {
		if ($(window).width() < 991) {
			$("hr").remove();
			$("#documents.row .record:nth-of-type(even)").after("<hr>");
		}
		else {
			$("hr").remove();
	    $("#documents.row .record:nth-of-type(3n)").after("<hr>");
		}
	}


});

// Listen for Button CLicks
$(document).ajaxSuccess(function() {
	//check window size and inserts an <hr> appropriately
	if ($(window).width() < 991) {
		$("#documents.row .record:nth-of-type(even)").after("<hr>");
	}
	else {
		$("hr").remove();
		$("#documents.row .record:nth-of-type(3n)").after("<hr>");
	}
});
