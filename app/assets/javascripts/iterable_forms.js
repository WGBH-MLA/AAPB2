$(function() {
    $("form.form-signup").on("submit", function(e) {
        e.preventDefault();
        var _that = $(this);

        email         = _that.find("#email").val();
        firstName     = _that.find("#firstName").val();
        lastName      = _that.find("#lastName").val();
        successPage   = _that.find(".success-page").val();
        captcha       = _that.find(".recaptcha-response").val();

        console.log('captcha: ' + captcha)
        // Send the request to verify client side response
        $.ajax({
            type: "POST",
            url: "/recaptcha",
            data: {
                action: "validate_recaptcha",
                recaptcha_response: captcha
            }
        }).always(function(captchaResp) {
            console.log(captchaResp);
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
    });
});