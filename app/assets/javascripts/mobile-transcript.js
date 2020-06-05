$(function() {
  // the input field
  var $mobileInput = $("input[type='mobile-search']"),
    // clear button
    $mobileClearBtn = $("button[data-search='mobile-clear']"),
    // prev button
    $mobilePrevBtn = $("button[data-search='mobile-prev']"),
    // next button
    $mobileNextBtn = $("button[data-search='mobile-next']"),
    // the context where to search
    $mobileContent = $(".mobile-transcript-content"),
    // jQuery object to save <mark> elements
    $mobileResults,
    // the class that will be appended to the current
    // focused element
    currentClass = "current",
    // ID used for Jquery scrolling and will be appended to
    // the current focused element
    currentId = "current",
    // top offset for the jump (the search bar)
    offsetTop = 15,
    // the current index of the focused element
    currentIndex = 0;

  /**
   * Jumps to the element matching the currentIndex
   */
  function jumpTo() {
    if ($mobileResults.length) {
      var position,
        $current = $mobileResults.eq(currentIndex);
      $mobileResults.removeClass(currentClass);
      $mobileResults.removeAttr("id");
      if ($current.length) {
        $current.addClass(currentClass);
        $current.attr("id", currentId)
        position = $current.offset().top - offsetTop;
        $("div.mobile-transcript-content").scrollTo(document.getElementById("current"));
      }
    }
  }
  /**
   * Searches for the entered keyword in the
   * specified context on input
   */
  $mobileInput.on("input", function() {
    var searchVal = this.value;
    $mobileContent.unmark({
      done: function() {
        var regex = new RegExp("\\b(" + searchVal + ")\\b", "gi");
        $mobileContent.markRegExp(
          regex, {
          done: function() {
            $mobileResults = $mobileContent.find("mark");
            currentIndex = 0;
            jumpTo();
          }
        });
      }
    });
  });

  /**
   * Clears the search
   */
  $mobileClearBtn.on("click", function() {
    $mobileContent.unmark();
    $mobileInput.val("").focus();
  });

  /**
   * Next and previous search jump to
   */
  $mobileNextBtn.add($mobilePrevBtn).on("click", function() {
    if ($mobileResults.length) {
      currentIndex += $(this).is($mobilePrevBtn) ? -1 : 1;
      if (currentIndex < 0) {
        currentIndex = $mobileResults.length - 1;
      }
      if (currentIndex > $mobileResults.length - 1) {
        currentIndex = 0;
      }
      jumpTo();
    }
  });
});
