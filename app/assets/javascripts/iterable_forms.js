$(function() {
    var _that = $(this);
    var successPage = _that.find(".success-page").val();
    var $recaptchaResponse = $('#recaptcha_response')

    function getRecaptchaTokenAndSubmit (){
        console.log("siteKey is:" + siteKey);
        grecaptcha.ready(function() {
            // do request for recaptcha token
            // response is promise with passed token
            grecaptcha.execute(siteKey, { action: 'subscribe' }).then(function(token) {
                // add token to form
                console.log('token is: ' + token)
                $recaptchaResponse.value = token;
                console.log('recaptchaResponse value: ' + $recaptchaResponse.value)
                submitRecaptcha();
            });
        });
    };

    function submitRecaptcha (){
        var captcha = $recaptchaResponse.value
        console.log('success-page: ' + successPage)
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
    }

    $("form.form-signup").on("submit", function(e) {
        e.preventDefault();
        getRecaptchaTokenAndSubmit();
    });
});