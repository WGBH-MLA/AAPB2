$(function() {
  var rand = Math.random()

  // whats the path
  let path = new URL(window.location.href).pathname

  // did we already trigger these modals
  let orr = getCookie("orr_rules_of_use")
  let nws = getCookie("newsletter")
  // duh
  let triggered_orr = false

  if(path.includes("/catalog/") && orr != "y"){
    console.log( 'now I did orr!', rand, orr )
    $('#rules-modal').modal({keyboard: true});
    triggered_orr = true
  }
  if(!triggered_orr && nws != "y"){
    console.log( 'now I did nws!', rand, nws )
    $('#newsletter-modal').modal({keyboard: true});
    // do cookie here because this one should not require affirmation to stop showing
    document.cookie = 'newsletter=y;max-age=15770000'
  }
});

function getCookie(cname) {
  let name = cname + "=";
  let decodedCookie = decodeURIComponent(document.cookie);
  let ca = decodedCookie.split(';');
  for(let i = 0; i <ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) == ' ') {
      c = c.substring(1);
    }
    if (c.indexOf(name) == 0) {
      return c.substring(name.length, c.length);
    }
  }
  return "";
}
