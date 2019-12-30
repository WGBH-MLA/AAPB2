// Imported from OpenVault with minor adjustments.
$(function() {

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

  function getTimecode() {
    // handle clicking share button when video hasn't been played
    tc = $player[0] ? $player[0].currentTime.toString() : '0.0';
    tc = tc.match(/\.\d+$/) ? tc : tc + '.0';
    return "#at_" + tc + "_s";
  }

  function getEmbedHtml() {
    var uri = window.location.protocol + '//' + window.location.hostname;
    // for dev env
    uri = window.location.port ? uri + ':' + window.location.port : uri;
    uri = uri + '/embed/';
    var radio = $('input.embed-at-time:checked');
    var tc = '';
    if(radio && radio.attr('id') == 'on') {
      tc = getTimecode();
    }
    var pbcore_guid = $('#pbcore-guid').text();
    var html = "<iframe style='display: flex; flex-direction: column; min-height: 50vh; width: 100%;' src='" + uri + pbcore_guid + tc + "'></iframe>".replace(/&/g, '&amp;');

    return html;
  };

  function getShareHtml() {
    var uri = window.location.protocol + '//' + window.location.hostname;
    // for dev env
    uri = window.location.port ? uri + ':' + window.location.port : uri;
    uri = uri + '/catalog/';
    var radio = $('input.share-at-time:checked');
    var tc = '';
    if(radio && radio.attr('id') == 'on') {
      tc = getTimecode();
    }
    var pbcore_guid = $('#pbcore-guid').text();
    var html = (uri + pbcore_guid + tc).replace(/&/g, '&amp;');

    return html;
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

  var $player = $('#player_media_html5_api');
  // chrome needs this!!
  if($player[0]){
    var url_hash = location.hash.match(/#at_(\d+(\.\d+))_s/);
    // If timecode included in URL, play to pass thumbnail,
    // then pause at that timecode.
    if (url_hash) {
      $player[0].currentTime = url_hash[1];
    }
  
  }

  $('#player_media').on('loadstart', function() {
    // firefox needs this!
    if(!$player[0]){
      console.log('fired loadstart')
      $player = $('#player_media').find('video');

    }
  });

  $('#player_media').on('durationchange', function() {
    console.log('fired duration change')

    // firefox needs this!
      var url_hash = location.hash.match(/#at_(\d+(\.\d+))_s/);
      // If timecode included in URL, play to pass thumbnail,
      // then pause at that timecode.
      if ($player[0] && url_hash) {
        $player[0].currentTime = url_hash[1];
      }

  });

  var $transcript = $('#transcript');

  var lines = {};
  $transcript.contents().find('[data-timecodebegin]').each(function(i,el){
      var $el = $(el);
      lines[parse_timecode($el.data('timecodebegin'))] = $el;
  });
  var sorted = Object.keys(lines).sort(function(a,b){return a - b;});
  // Browser seems to preserve key order, but don't rely on that.
  // JS default sort is lexicographic.

  $player.on('timeupdate', function(){
      var current = $player[0].currentTime;
      var key = greatest_less_than_or_equal_to(current);
      var $line = lines[key];
      var class_name = 'current';
      if ($line && !$line.hasClass(class_name)) {
          $transcript.contents().find('[data-timecodebegin]').removeClass(class_name);
          $line.addClass(class_name);
      };
      if (!is_user_scroll()) {
          if($line){
            $('iframe').contents().scrollTop($line.position().top-30);
          }
          // "-30" to get the speaker's name at the top;
          // ... but when a single monologue is broken into
          // parts this doesn't look as good: we get a line
          // of the previous section just above.
          // TODO: tweak xslt to move time attributes
          // up to the containing element.
          window.setTimeout(function() {
              set_user_scroll(false);
          }, 100); // 0.1 seconds
          // The scrollTop triggers a scroll event,
          // but the handler has no way to distinguish
          // a scroll generated by JS and one that
          // actually comes from a user...
          // so wait a bit and then set to the
          // correct (false) user_scroll state.
      }
  });

  $player.on('mouseenter play', function(){
      set_user_scroll(false);
  });

  $('.play-from-here').unbind('click').on('click', function(){
    var time = parse_timecode($(this).data('timecode'));
    location.hash = '#at_' + time + '_s';
    $player[0].currentTime = time;
    $player[0].play();
    set_user_scroll(false);
  });

  $transcript.contents().scroll(function(){
      set_user_scroll(true);
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

  // New for AAPB.
  var $divTranscript = $('div.transcript-div');
  var $divPlayer = $('div.player');
  var $divExhibitPromo = $('div.exhibit-promo');

  if($('#player_media').length != 0){
    var player = videojs('#player_media');
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

  $('.embed-at-time').change(function() {
    $('#timecode-embed').val(getEmbedHtml());
  });

  $('.share-at-time').change(function() {
    $('#timecode-share').val(getShareHtml());
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
    $('#timecode-share').val(getShareHtml());
  });

});
