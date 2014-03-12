;(function( window, $, undefined ) {

"use strict";

$.fn.dragdrop = function() {
  $(this).attr("data-draggable", "true");

  $(this).live({
    "mousedown": function( e ) {
      var t = $(this)

      if ( t.attr("data-draggable") === "true" ) {
        t.css("position", "absolute");
        t.addClass("dragging");
      }
    },

    "mousemove": function( e ) {
      console.log(e.pageX);
      t.css({ "left": e.pageX, "top": e.pageY });
    },

    "mouseup": function( e ) {
      var t = $(this);

      t.css("position", "normal");
      t.removeClass("dragging");
    }
  });
};

})( window, window.jQuery );
