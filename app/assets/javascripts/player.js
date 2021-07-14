// Imported from OpenVault with minor adjustments.
window.onunload = function(){};
$(function() {

  $slider_positions = [];
  $current_handle = null;

  function getParameterByName(name) {
    var url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
  }

  function updateTranscriptGrid() {
    if ($divTranscript.hasClass('col-md-2')) {
      $divTranscript.addClass('col-md-6').removeClass('col-md-2');
    } else if ($divTranscript.hasClass('col-md-6'))  {
      $divTranscript.addClass('col-md-2').removeClass('col-md-6');
    }
    showTranscript();
  }
  function showTranscript() {
    if ($divTranscript.hasClass('transcript-view-hidden')) {
      $divTranscript.addClass('transcript-view-show').removeClass('transcript-view-hidden');
    } else if ($divTranscript.hasClass('transcript-view-show')) {
      $divTranscript.addClass('transcript-view-hidden').removeClass('transcript-view-show');
    }
  }

  function updatePlayerGrid() {
    if(!player){
      return;
    }
    var playerHeight = player.height();
    var playerWidth = player.width();

    if ($divPlayer.hasClass('col-md-8') && $divPlayer.hasClass('player')) {
      $divPlayer.addClass('col-md-6');
      $divPlayer.removeClass('col-md-offset-2').removeClass('col-md-8');
      $divExhibitPromo.addClass('col-md-6');
      $divExhibitPromo.removeClass('col-md-offset-2').removeClass('col-md-8');
    } else if ($divPlayer.hasClass('col-md-6') && $divPlayer.hasClass('player'))  {
      $divPlayer.addClass('col-md-offset-2').addClass('col-md-8');
      $divPlayer.removeClass('col-md-6');
      $divExhibitPromo.addClass('col-md-offset-2').addClass('col-md-8');
      $divExhibitPromo.removeClass('col-md-6');
    }
  }

  function updateTranscriptButton() {
    var sliders = document.getElementsByClassName("transcript-slide");
    for(var i = 0; i < sliders.length; ++i){
      var slide = sliders[i];
      if (slide.classList.contains('show-transcript')) {
        slide.innerHTML = 'Show<div class="transcript-circle">+</div>';
        slide.classList.remove('show-transcript');
        search.removeClass('show-transcript-search');
      } else if (!slide.classList.contains('show-transcript')) {
        slide.innerHTML = 'Hide<div class="transcript-circle">-</div>';
        slide.classList.add('show-transcript');
        search.addClass('show-transcript-search');
      };
    }
  }

  function getTimeMarkers() {
    var start = getParameterByName('start');
    var end = getParameterByName('end');

    if(start && end){
      return [start, end];
    }
  }

  function getTimeMarkerQuery() {
    var start = parseFloat($('#start-time').text());
    var end = parseFloat($('#end-time').text());
    return '?start=' + start + '&end=' + end;
  }

  function convertTimeCodeToSeconds(timeString) {

    var timeArray = timeString.split(":");
    var hours   = parseInt(timeArray[0]) * 60 * 60;
    var minutes = parseInt(timeArray[1]) * 60;
    var seconds = parseInt(timeArray[2]);
    var frames  = 0;
    var totalTime = hours + minutes + seconds + frames;
    return totalTime;
  }

  function addRangeSlider() {
    var value = "0,"+$video_duration;

    noUiSlider.create($con, {
        start: [0, $video_duration],
        connect: true,
        range: {
            'min': 0,
            'max': $video_duration
        }
    });

    $('.noUi-touch-area').each(function(index, handle){
      $(handle).attr('id', 'handle-' + index);
    });
  }

  function getHost(){
    var uri = window.location.protocol + '//' + window.location.hostname;
    // for dev env
    return window.location.port ? uri + ':' + window.location.port : uri;
  }

  function getShareGuts(uri){
    var pbcore_guid = $('#pbcore-guid').text();

    var radio = $('input.share-at-time:checked');
    if(radio && radio.attr('id') == 'on') {
      // segment of whatever / slider
      var tm = getTimeMarkerQuery();
      return pbcore_guid + tm;
    } else if(radio && radio.attr('id') == 'current'){
      // #at_time_s
      return pbcore_guid + '?proxy_start_time=' + player.currentTime();
    } else {
      // start at beginning
      return pbcore_guid;
    }

  }

  function getEmbedHtml() {
    var uri = getHost() + '/embed/' + getShareGuts();
    var html = "<iframe style='display: flex; flex-direction: column; min-height: 50vh; width: 100%;' src='" + uri + "'></iframe>".replace(/&/g, '&amp;');
    return html;
  };

  function getShareUrl() {
    return getHost() + '/catalog/' + getShareGuts();
  };

  function parse_timecode(hms) {
      var arr = hms.split(':');
      return parseFloat(arr[2]) +
             60 * parseFloat(arr[1]) +
             60*60 * parseFloat(arr[0]);
  }

  function greatest_less_than_or_equal_to(t) {
      var last = 0;
      for (var i=0; i < sorted.length; i++) {
          if (sorted[i] <= t) {
              last = sorted[i];
          } else {
              return last;
          }
      }
  };

  function set_user_scroll(state) {
      $player.data('user-scroll', state);
  }

  function is_user_scroll() {
      return $player.data('user-scroll');
  }

  function skipPlayer(forward) {
    var now = player.currentTime();
    if(forward){
      player.currentTime(now+10);
    } else {
      player.currentTime(now-10);
    }
  }

  function toTC(int_seconds){
    var date = new Date(0)
    date.setSeconds(int_seconds);
    return date.toISOString().substr(11, 8);
  }

  var $transcript = $('#transcript');

  var lines = {};
  $transcript.contents().find('[data-timecodebegin]').each(function(i,el){
      var $el = $(el);
      lines[parse_timecode($el.data('timecodebegin'))] = $el;
  });
  var sorted = Object.keys(lines).sort(function(a,b){return a - b;});
  // Browser seems to preserve key order, but don't rely on that.
  // JS default sort is lexicographic.

  var $player = $('#player_media_html5_api');
  // chrome needs this!!
  if($player[0]){
    var proxyStartTime = getParameterByName('proxy_start_time');
    // If timecode included in URL, play to pass thumbnail,
    // then pause at that timecode.
    if (proxyStartTime) {
      $player[0].currentTime = proxyStartTime;

      var key = greatest_less_than_or_equal_to($player[0].currentTime);
      var $line = lines[key];

      // only scroll transcript if there actually is a transcript
      if($line){
        $transcript.contents().scrollTop($line.position().top-40);
      }
    }
  }

  // set time range values
  $con = $('#time-range')[0];
  $video_duration = parseInt($('#video-duration').text());

  // only do it if theres a duration value
  if($video_duration > 0){

    $('#time-range-switch').click(function() {
      $('#time-range-container').slideToggle();
    });

    addRangeSlider();

    $con.noUiSlider.on('update', function(e) {
      var new_slider_positions = $con.noUiSlider.get();
      $('#start-time').text( new_slider_positions[0] );
      $('#end-time').text( new_slider_positions[1] );

      $('#start-display').text( toTC(new_slider_positions[0]) );
      $('#end-display').text( toTC(new_slider_positions[1]) );

      if($current_handle == 0 || $current_handle == 1){
        player.currentTime($slider_positions[$current_handle]);
      }

      $slider_positions = new_slider_positions;
    });
  }

  $('.noUi-touch-area').mousedown(function(e) {
    // set current_handle to 0 or 1
    $current_handle = parseInt(e.target.id.slice(-1));
  });

  $('.noUi-touch-area').on('touchstart', function(e) {
    // set current_handle to 0 or 1
    $current_handle = parseInt(e.target.id.slice(-1));
  });

  $('#player_media').on('loadstart', function() {
    // firefox needs this!
    if(!$player[0]){
      $player = $('#player_media').find('video,audio');
    }
  });

  $('#player_media').on('durationchange', function() {
    // firefox needs this!
    var proxyStartTime = getParameterByName('proxy_start_time');
    // If timecode included in URL, play to pass thumbnail,
    // then pause at that timecode.
    if ($player[0] && proxyStartTime) {
      $player[0].currentTime = proxyStartTime;
    }
  });

  $player.on('timeupdate', function(){
    var current = $player[0].currentTime;
    var key = greatest_less_than_or_equal_to(current);
    var $line = lines[key];
    var class_name = 'current';
    if ($line && !$line.hasClass(class_name)) {
        $transcript.contents().find('[data-timecodebegin]').removeClass(class_name);
        $line.addClass(class_name);
    };
  });

  $('.play-from-here').unbind('click').on('click', function(){
    var time = parse_timecode($(this).data('timecode'));
    $player[0].currentTime = time;
    $player[0].play();
  });

  $(document).keypress(function(e) {
    if(e.keyCode == 37) {
      $('button#skip-back').trigger('click');
    } else if (e.keyCode == 39) {
      $('button#skip-forward').trigger('click');
    }
  });

  $('button#skip-back').unbind('click').click(function() {
    skipPlayer(false);
  });

  $('button#skip-forward').unbind('click').click(function() {
    skipPlayer(true);
  });

  var $divTranscript = $('div.transcript-div');
  var $divPlayer = $('div.player');
  var $divExhibitPromo = $('div.exhibit-promo');

  if($('#player_media').length != 0){
    var player = videojs('#player_media');

    var time_markers = getTimeMarkers();
    if(time_markers){
      $('#time-range-switch-container, #time-range-container').hide();

      player.offset({
        start: time_markers[0],
        end: time_markers[1],
        restart_beginning: false //Should the video go to the beginning when it ends
      });

      $('#clip-message-container').show();
    }
  }

  var exhibit = $('#exhibit-banner');
  var search = $('div.transcript-search');
  var searchInput = $('.transcript-search-input')
  var searchTotalElem = $('div.transcript-search-results');
  var searchButton = $('#transcript-search-btn');

  $('div.transcript-slide').unbind('click').on('click', function(){
    updatePlayerGrid();
    updateTranscriptGrid();
    updateTranscriptButton();
  });

  // hide player once (thanks turbolinks!)
  var tstate = $('#transcript-state');
  if(tstate.hasClass('closed') && tstate.hasClass('initial')) {
    tstate.removeClass('initial');
    updatePlayerGrid()
    updateTranscriptGrid();
    updateTranscriptButton();
  }

  $('#transcript-message-close').unbind('click').on('click', function() {
    $('#transcript-message').slideUp(500);
  });

  $('.share-at-time').change(function() {
    $('#timecode-embed').val(getEmbedHtml());
    $('#timecode-share').val(getShareUrl());
  });

  $('#embed-copy-button').click(function() {
    /* Get the text field */
    var copyText = document.getElementById('timecode-embed');

    /* Select the text field */
    copyText.select();
    copyText.setSelectionRange(0, 99999); /*For mobile devices*/

    /* Copy the text inside the text field */
    document.execCommand('copy');
  });

  $('#share-copy-button').click(function() {
    /* Get the text field */
    var copyText = document.getElementById('timecode-share');

    /* Select the text field */
    copyText.select();
    copyText.setSelectionRange(0, 99999); /*For mobile devices*/

    /* Copy the text inside the text field */
    document.execCommand('copy');
  });

  // initialize share modal content when button is clicked, so we getta the current timecode
  $('#content-share').click(function() {
    $('#timecode-embed').val(getEmbedHtml());
    $('#timecode-share').val(getShareUrl());
  });

});
