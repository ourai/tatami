"use strict";

$.fn.dragdrop = ->
  $(this).attr "data-draggable", "true"

  $(this).live
    mousedown: ( e ) ->
      t = $(this)

      if t.attr("data-draggable") is "true"
        t.css "position", "absolute"
        t.addClass "dragging"

    mousemove: ( e ) ->
      console.log e.pageX
      t.css left: e.pageX, top: e.pageY

    mouseup: ( e ) ->
      t = $(this)

      t.css "position", "normal"
      t.removeClass "dragging"
