$(function() {
  // the input field
  var $input = $("input[type='search']"),
    // clear button
    $clearBtn = $("button[data-search='clear']"),
    // prev button
    $prevBtn = $("button[data-search='prev']"),
    // next button
    $nextBtn = $("button[data-search='next']"),
    // the context where to search
    $content = $(".transcript-content"),
    // jQuery object to save <mark> elements
    $results,
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
    if ($results.length) {
      var position,
        $current = $results.eq(currentIndex);
      $results.removeClass(currentClass);
      $results.removeAttr("id");
      if ($current.length) {
        $current.addClass(currentClass);
        $current.attr("id", currentId)
        position = $current.offset().top - offsetTop;
        $("div.transcript-content").scrollTo(document.getElementById("current"));
      }
    }
  }
  /**
   * Searches for the entered keyword in the
   * specified context on input
   */
  $input.on("input", function() {
    var searchVal = this.value;
    $content.unmark({
      done: function() {
        var regex = new RegExp("\\b(" + searchVal + ")\\b", "gi");
        $content.markRegExp(
          regex, {
          done: function() {
            $results = $content.find("mark");
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
  $clearBtn.on("click", function() {
    $content.unmark();
    $input.val("").focus();
  });

  /**
   * Next and previous search jump to
   */
  $nextBtn.add($prevBtn).on("click", function() {
    if ($results.length) {
      currentIndex += $(this).is($prevBtn) ? -1 : 1;
      if (currentIndex < 0) {
        currentIndex = $results.length - 1;
      }
      if (currentIndex > $results.length - 1) {
        currentIndex = 0;
      }
      jumpTo();
    }
  });
});
