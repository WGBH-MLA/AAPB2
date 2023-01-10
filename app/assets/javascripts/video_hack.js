$divPlayer = $('div.player')


if ($divPlayer.hasClass('col-md-8') && $divPlayer.hasClass('player')) {
  // side by side player and ts viewer

  $divPlayer.addClass('col-md-6');
  $divPlayer.removeClass('col-md-offset-2').removeClass('col-md-8');
  $divExhibitPromo.addClass('col-md-6');
  $divExhibitPromo.removeClass('col-md-offset-2').removeClass('col-md-8');
} else if ($divPlayer.hasClass('col-md-6') && $divPlayer.hasClass('player'))  {
  // push minimized transcript viewer panel down below player

  $divPlayer.addClass('col-md-offset-2').addClass('col-md-8');
  $divPlayer.removeClass('col-md-6');
  $divExhibitPromo.addClass('col-md-offset-2').addClass('col-md-8');
  $divExhibitPromo.removeClass('col-md-6');
}
