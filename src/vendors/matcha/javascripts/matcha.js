(function( global, factory ) {

  if ( typeof module === "object" && typeof module.exports === "object" ) {
    module.exports = global.document ?
      factory(global, true) :
      function( w ) {
        if ( !w.document ) {
          throw new Error("Requires a window with a document");
        }
        return factory(w);
      };
  } else {
    factory(global);
  }

}(typeof window !== "undefined" ? window : this, function( window, noGlobal ) {

"use strict";
var LIB_CONFIG, getStorageData, hasOwnProp, hook, storage, _H;

LIB_CONFIG = {
  name: "Matcha",
  version: "0.1.1"
};

_H = {};

storage = {

  /*
   * JavaScript 钩子
   *
   * @property   hook
   * @type       {Object}
   */
  hook: {
    tabs: {
      component: "tabs",
      trigger: "tabs-trigger",
      content: "tabs-content"
    }
  }
};


/*
 * 判断某个对象是否有自己的指定属性
 *
 * !!! 不能用 object.hasOwnProperty(prop) 这种方式，低版本 IE 不支持。
 *
 * @private
 * @method   hasOwnProp
 * @return   {Boolean}
 */

hasOwnProp = function(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
};


/*
 * 获取指定钩子
 *
 * @private
 * @method   hook
 * @param    name {String}     Hook's name
 * @param    no_dot {Boolean}  Return class when true, default is selector
 * @return   {String}
 */

hook = function(name, no_dot) {
  return (no_dot === true ? "" : ".") + "js-" + $.camelCase(getStorageData("hook." + name));
};


/*
 * Get data from internal storage
 *
 * @private
 * @method   getStorageData
 * @param    ns_str {String}   Namespace string
 * @return   {String}
 */

getStorageData = function(ns_str) {
  var parts, result;
  parts = ns_str.split(".");
  result = storage;
  $.each(parts, function(idx, part) {
    var rv;
    rv = hasOwnProp(result, part);
    result = result[part];
    return rv;
  });
  return result;
};

window[LIB_CONFIG.name] = _H;

}));
