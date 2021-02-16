$(function() {
  var bgVideo = $("#video-background")[0];
  var bgButton = $("#video-bg-control");

  bgButton.on("click", function(){
    var $this = $(this)
    if ($this.hasClass('video-bg-play')) {
      $this.html('Play Video').addClass('video-bg-pause').removeClass('video-bg-play').attr('aria-label','Play Video');
      bgVideo.pause();
    } else if ($this.hasClass('video-bg-pause')) {
      $this.html('Pause Video').addClass('video-bg-play').removeClass('video-bg-pause').attr('aria-label','Pause Video');
      bgVideo.play();
    }
  });
});
