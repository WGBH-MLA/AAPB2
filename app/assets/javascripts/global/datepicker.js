$(function() {

    // Bind all input elements with class datepicker to datepicker plugin
    $( "input.datepicker" ).datepicker({
        dateFormat: "yy-mm-dd"
    });

    // Use Hydra Editor Event to add date picker for multi value attributes
    if($('.multi_value.form-group').length ) {
        $('.multi_value.form-group', $("form[data-behavior='work-form']")[0]).on('managed_field:add', function (e, child) {
            if (child) {
                $(child).attr("id", child.id + "_" + $.now());
                if ($(child).hasClass("hasDatepicker")) {
                    $(child).removeClass("datepicker hasDatepicker");
                    $(child).datepicker({
                        dateFormat: "yy-mm-dd"
                    });
                }
            }
        });
    }
});

