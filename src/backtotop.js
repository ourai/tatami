;(function( window, $, undefined ) {

"use strict";

$.fn.backtotop = function() {
  var btn = $(this);
  var body = document.body;
  var html = document.documentElement;
  var tagName;

  btn.click(function() {
    if ( body.scrollTop ) {
      tagName = "body";
    }
    else if ( html.scrollTop ) {
      tagName = "html";
    }

    if ( tagName ) {
      $(tagName).animate({ scrollTop: 0 });
    }

    return false;
  });

  $(window).scroll(function() {
    if ( (body.scrollTop || html.scrollTop) > 200 ) {
      btn.fadeOut();
    }
    else {
      btn.fadeIn();
    }
  });
};
  
})( window, window.jQuery );
