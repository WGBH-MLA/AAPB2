/* Set up for use with Turbolinks */
var indexReady = function() {
  $("#loading-icon").addClass('hidden');

  $("body").on('click', '.dropdown-menu li a', function() {
    $("#loading-icon").removeClass('hidden');
  });
};

$(document).ready(indexReady);
$(document).on('page:load', indexReady);
