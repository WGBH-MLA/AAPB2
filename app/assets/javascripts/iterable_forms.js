$(function() {
    var $recaptchaResponse = $('#recaptcha_response')

    function getRecaptchaTokenAndSubmit (_that){
        grecaptcha.ready(function() {
            // do request for recaptcha token
            // response is promise with passed token
            grecaptcha.execute(siteKey, { action: 'subscribe' }).then(function(token) {
                // add token to form
                $recaptchaResponse.value = token;
                var successPage = _that.find(".success-page").val();
                submitRecaptcha(_that, successPage);
            });
        });
    };

    function submitRecaptcha (_that, successPage){
        var captcha = $recaptchaResponse.value
        // Send the request to verify client side response
        $.ajax({
            type: "POST",
            url: "/recaptcha",
            data: {
                action: "validate_recaptcha",
                recaptcha_response: captcha
            }
        }).always(function(captchaResp) {
            if (captchaResp.success) {
                // Clean and send
                $.ajax({
                    url: _that.attr("action"),
                    data: _that.serialize(), // form data
                    type: _that.attr("method"), //
                    error: function(err) {
                        alert("There was a problem adding you the list. Please try again later.");
                    },
                    success: function(data) {
                        window.location.href = successPage;
                    }
                });
            } else {
                // Show the user an error and don't submit
                alert("reCAPTCHA verification failed, please try again later.");
            }
        });
    }

    $("form.form-signup").on("submit", function(e) {
        e.preventDefault();
        var _that = $(this);
        getRecaptchaTokenAndSubmit(_that);
    });
});