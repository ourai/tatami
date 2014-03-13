"use strict";

$.fn.backtotop = ->
  btn = $(this)
  body = document.body
  html = document.documentElement
  tagName = undefined

  btn.click ->
    if body.scrollTop
      tagName = "body"
    else if html.scrollTop
      tagName = "html"

    $(tagName).animate scrollTop: 0 if tagName

    return false

  $(window).scroll ->
    if (body.scrollTop || html.scrollTop) > 200
      btn.fadeOut()
    else
      btn.fadeIn()
