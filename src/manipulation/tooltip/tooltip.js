;(function( window, $, undefined ) {

"use strict";

// IE8 以下浏览器跳出
if ( !$ || ($.browser.msie && $.browser.version < 8) ) {
  return false;
}

$.fn.tooltip = function() {
  // settings = {
  //   tooltipClass: String,
  //   content: Function / String
  // }
  var settings = $.extend({}, arguments[0]);
  var selector = $(this).selector;
  var card = initTooltipCard(selector, settings.tooltipClass);

  $(this).each(function() {
    var t = $(this);
  });
};

function initTooltipCard( selector, tooltipClass ) {
  var cls = "h-tooltip";
  var isCreate = false;
  var map = {};

  tooltipClass = typeof tooltipClass === "string" && $.trim(tooltipClass) !== "" ? $.trim(tooltipClass) : null;

  if ( tooltipClass && !$("." + tooltipClass).is("." + cls) ) {
    isCreate = true;
    cls += (" " + tooltipClass);
  }
  else if ( !$("." + cls).size() ) {
    isCreate = true;
  }
  else if ( $("." + cls).attr("class") !== cls ) {
    isCreate = true;
  }

  var card = Hanger.data("tooltip." + selector);

  if ( isCreate && card === null ) {
    card = $("<div class=\"" + cls + "\" />");

    card.append("<div class=\"h-tooltip-content\" />").appendTo($("body"));

    map[selector] = card;

    Hanger.data("tooltip", map);
  }

  return card;
}

})( window, window.jQuery );
