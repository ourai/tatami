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
var $, ATTRIBUTE_NODE, CDATA_SECTION_NODE, COMMENT_NODE, DOCUMENT_FRAGMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE, ELEMENT_NODE, ENTITY_NODE, ENTITY_REFERENCE_NODE, LIB_CONFIG, NOTATION_NODE, PROCESSING_INSTRUCTION_NODE, REG_NAMESPACE, TEXT_NODE, api_ver, bindHandler, clone, constructDatasetByAttributes, constructDatasetByHTML, getStorageData, initialize, initializer, isExisted, isLimited, last, limit, limiter, pushHandler, request, resetConfig, runHandler, setData, setStorageData, setup, storage, support, systemDialog, systemDialogHandler, _ENV, _H;

LIB_CONFIG = {
  name: "Tatami",
  version: "0.2.1"
};

ELEMENT_NODE = 1;

ATTRIBUTE_NODE = 2;

TEXT_NODE = 3;

CDATA_SECTION_NODE = 4;

ENTITY_REFERENCE_NODE = 5;

ENTITY_NODE = 6;

PROCESSING_INSTRUCTION_NODE = 7;

COMMENT_NODE = 8;

DOCUMENT_NODE = 9;

DOCUMENT_TYPE_NODE = 10;

DOCUMENT_FRAGMENT_NODE = 11;

NOTATION_NODE = 12;

REG_NAMESPACE = /^[0-9A-Z_.]+[^_.]?$/i;

$ = jQuery;

_ENV = {
  lang: document.documentElement.lang || document.documentElement.getAttribute("lang") || navigator.language || navigator.browserLanguage
};

_H = Ronin;

_H.mask(LIB_CONFIG.name);

_H.__meta__ = LIB_CONFIG;

support = {
  storage: !!window.localStorage
};

limiter = {

  /*
   * 键
   *
   * @property  key
   * @type      {Object}
   */
  key: {
    storage: ["sandboxStarted", "config", "fn", "buffer", "pool", "i18n", "web_api"]
  }
};

storage = {

  /*
   * 沙盒运行状态
   *
   * @property  sandboxStarted
   * @type      {Boolean}
   */
  sandboxStarted: false,

  /*
   * 配置
   *
   * @property  config
   * @type      {Object}
   */
  config: {
    debug: true,
    platform: "",
    api: "",
    locale: _ENV.lang,
    lang: _ENV.lang.split("-")[0]
  },

  /*
   * 函数
   *
   * @property  fn
   * @type      {Object}
   */
  fn: {
    prepare: [],
    ready: [],
    init: {
      systemDialog: $.noop,
      ajaxHandler: function(succeed, fail) {
        return {
          success: function(data, textStatus, jqXHR) {
            var args;
            args = _H.slice(arguments);

            /*
             * 服务端在返回请求结果时必须是个 JSON，如下：
             *    {
             *      "code": {Integer}       # 处理结果代码，code > 0 为成功，否则为失败
             *      "message": {String}     # 请求失败时的提示信息
             *    }
             */
            if (data.code > 0) {
              if (_H.isFunction(succeed)) {
                return succeed.apply($, args);
              }
            } else {
              if (_H.isFunction(fail)) {
                return fail.apply($, args);
              } else {
                return systemDialog("alert", data.message);
              }
            }
          },
          error: $.noop
        };
      }
    },
    handler: {}
  },

  /*
   * 缓冲区，存储临时数据
   *
   * @property  buffer
   * @type      {Object}
   */
  buffer: {},

  /*
   * 对象池
   * 
   * @property  pool
   * @type      {Object}
   */
  pool: {},

  /*
   * 国际化
   *
   * @property  i18n
   * @type      {Object}
   */
  i18n: {
    _SYS: {
      dialog: {
        zh: {
          title: "系统提示",
          close: "关闭",
          ok: "确定",
          cancel: "取消",
          yes: "是",
          no: "否"
        },
        en: {
          title: "System",
          close: "Close",
          ok: "Ok",
          cancel: "Cancel",
          yes: "Yes",
          no: "No"
        }
      }
    }
  },

  /*
   * Web API
   *
   * @property  api
   * @type      {Object}
   */
  web_api: {}
};


/*
 * 取得数组或类数组对象中最后一个元素
 *
 * @private
 * @method  last
 * @return
 */

last = function(array) {
  return _H.slice(array, -1)[0];
};


/*
 * 全局配置
 * 
 * @private
 * @method    setup
 */

setup = function() {
  $.ajaxSetup({
    type: "post",
    dataType: "json"
  });
  return $(document).ajaxError(function(event, jqXHR, ajaxSettings, thrownError) {
    var response;
    response = jqXHR.responseText;
    return false;
  });
};


/*
 * 生成自定义系统对话框
 * 
 * @private
 * @method  systemDialog
 * @param   type {String}
 * @param   message {String}
 * @param   okHandler {Function}
 * @param   cancelHandler {Function}
 * @return  {Boolean}
 */

systemDialog = function(type, message, okHandler, cancelHandler) {
  var dlg, i18nText, poolName, result;
  result = false;
  if (_H.isString(type)) {
    type = type.toLowerCase();
    if (_H.isFunction($.fn.dialog)) {
      poolName = "systemDialog";
      i18nText = storage.i18n._SYS.dialog[_H.config("lang")];
      if (!_H.hasProp(poolName, storage.pool)) {
        storage.pool[poolName] = {};
      }
      dlg = storage.pool[poolName][type];
      if (!dlg) {
        dlg = $("<div data-role=\"dialog\" data-type=\"system\" />").appendTo($("body")).on({
          dialogcreate: initializer("systemDialog"),
          dialogopen: function(e, ui) {
            return $(".ui-dialog-buttonset .ui-button", $(this).closest(".ui-dialog")).each(function() {
              var btn;
              btn = $(this);
              switch (_H.trim(btn.text())) {
                case i18nText.ok:
                  type = "ok";
                  break;
                case i18nText.cancel:
                  type = "cancel";
                  break;
                case i18nText.yes:
                  type = "yes";
                  break;
                case i18nText.no:
                  type = "no";
              }
              return btn.addClass("ui-button-" + type);
            });
          }
        }).dialog({
          title: i18nText.title,
          width: 400,
          minHeight: 100,
          closeText: i18nText.close,
          modal: true,
          autoOpen: false,
          resizable: false,
          closeOnEscape: false
        });
        storage.pool[poolName][type] = dlg;
        dlg.closest(".ui-dialog").find(".ui-dialog-titlebar-close").remove();
      }
      result = systemDialogHandler(type, message, okHandler, cancelHandler);
    } else {
      result = true;
      if (type === "alert") {
        window.alert(message);
      } else {
        if (window.confirm(message)) {
          if (_H.isFunction(okHandler)) {
            okHandler();
          }
        } else {
          if (_H.isFunction(cancelHandler)) {
            cancelHandler();
          }
        }
      }
    }
  }
  return result;
};


/*
 * 系统对话框的提示信息以及按钮处理
 * 
 * @private
 * @method  systemDialogHandler
 * @param   type {String}             对话框类型
 * @param   message {String}          提示信息内容
 * @param   okHandler {Function}      确定按钮
 * @param   cancelHandler {Function}  取消按钮
 * @return
 */

systemDialogHandler = function(type, message, okHandler, cancelHandler) {
  var btnText, btns, dlg, dlgContent, handler, i18nText;
  i18nText = storage.i18n._SYS.dialog[_H.config("lang")];
  handler = function(cb, rv) {
    $(this).dialog("close");
    if (_H.isFunction(cb)) {
      cb();
    }
    return rv;
  };
  btns = [];
  btnText = {
    ok: i18nText.ok,
    cancel: i18nText.cancel,
    yes: i18nText.yes,
    no: i18nText.no
  };
  dlg = storage.pool.systemDialog[type];
  dlgContent = $("[data-role='dialog-content']", dlg);
  if (dlgContent.size() === 0) {
    dlgContent = dlg;
  }
  if (type === "confirm") {
    btns.push({
      text: btnText.ok,
      click: function() {
        handler.apply(this, [okHandler, true]);
        return true;
      }
    });
    btns.push({
      text: btnText.cancel,
      click: function() {
        handler.apply(this, [cancelHandler, false]);
        return true;
      }
    });
  } else if (type === "confirmex") {
    btns.push({
      text: btnText.yes,
      click: function() {
        handler.apply(this, [okHandler, true]);
        return true;
      }
    });
    btns.push({
      text: btnText.no,
      click: function() {
        handler.apply(this, [cancelHandler, false]);
        return true;
      }
    });
    btns.push({
      text: btnText.cancel,
      click: function() {
        handler.apply(this, [null, false]);
        return true;
      }
    });
  } else {
    type = "alert";
    if (okHandler !== null) {
      btns.push({
        text: btnText.ok,
        click: function() {
          handler.apply(this, [okHandler, true]);
          return true;
        }
      });
    } else {
      btns = null;
    }
  }
  dlgContent.html(message || "");
  return dlg.dialog("option", "buttons", btns).dialog("open");
};


/*
 * 将处理函数绑定到内部命名空间
 * 
 * @private
 * @method  bindHandler
 * @return
 */

bindHandler = function() {
  var args, fnList, func, funcName, handler, name;
  args = arguments;
  name = args[0];
  handler = args[1];
  fnList = storage.fn.handler;
  if (args.length === 0) {
    handler = clone(fnList);
  } else if (_H.isString(name)) {
    if (_H.isFunction(handler)) {
      fnList[name] = handler;
    } else {
      handler = fnList[name];
    }
  } else if (_H.isPlainObject(name)) {
    for (funcName in name) {
      func = name[funcName];
      if (_H.isFunction(func)) {
        fnList[funcName] = func;
      }
    }
  }
  return handler;
};


/*
 * 执行指定函数
 * 
 * @private
 * @method  runHandler
 * @param   name {String}         函数名
 * @param   [args, ...] {List}    函数的参数
 * @return  {Variant}
 */

runHandler = function(name) {
  var func, result, _i, _len;
  result = null;
  if (_H.isArray(name)) {
    for (_i = 0, _len = name.length; _i < _len; _i++) {
      func = name[_i];
      if (_H.isFunction(func) || _H.isFunction(func = storage.fn.handler[func])) {
        func.call(window);
      }
    }
  } else if (_H.isString(name)) {
    func = storage.fn.handler[name];
    if (_H.isFunction(func)) {
      result = func.apply(window, _H.slice(arguments, 1));
    }
  }
  return result;
};


/*
 * 将函数加到指定队列中
 * 
 * @private
 * @method  pushHandler
 * @param   handler {Function}    函数
 * @param   queue {String}        队列名
 */

pushHandler = function(handler, queue) {
  if (_H.isFunction(handler)) {
    return storage.fn[queue].push(handler);
  }
};


/*
 * 克隆对象并返回副本
 * 
 * @private
 * @method  clone
 * @param   source {Object}       源对象，只能为数组或者纯对象
 * @return  {Object}
 */

clone = function(source) {
  var result;
  result = null;
  if (_H.isArray(source) || source.length !== void 0) {
    result = [].concat([], _H.slice(source));
  } else if (_H.isPlainObject(source)) {
    result = $.extend(true, {}, source);
  }
  return result;
};


/*
 * 获取初始化函数
 * 
 * @private
 * @method  initializer
 * @return  {Function}
 */

initializer = function(key) {
  return storage.fn.init[key];
};


/*
 * Get data from internal storage
 *
 * @private
 * @method  getStorageData
 * @param   ns_str {String}   Namespace string
 * @param   ignore {Boolean}  忽略对 storage key 的限制
 * @return  {String}
 */

getStorageData = function(ns_str, ignore) {
  var parts, result;
  parts = ns_str.split(".");
  result = null;
  if (ignore || !isLimited(parts[0], limiter.key.storage)) {
    result = storage;
    _H.each(parts, function(part) {
      var rv;
      rv = _H.hasProp(part, result);
      result = result[part];
      return rv;
    });
  }
  return result;
};


/*
 * Set data into internal storage
 *
 * @private
 * @method  setStorageData
 * @param   ns_str {String}   Namespace string
 * @param   data {Variant}    
 * @return  {Variant}
 */

setStorageData = function(ns_str, data) {
  var isObj, key, length, parts, result;
  parts = ns_str.split(".");
  length = parts.length;
  isObj = _H.isPlainObject(data);
  if (length === 1) {
    key = parts[0];
    result = setData(storage, key, data, _H.hasProp(key, storage));
  } else {
    result = storage;
    _H.each(parts, function(n, i) {
      if (i < length - 1) {
        if (!_H.hasProp(n, result)) {
          result[n] = {};
        }
      } else {
        result[n] = setData(result, n, data, _H.isPlainObject(result[n]));
      }
      result = result[n];
      return true;
    });
  }
  return result;
};

setData = function(target, key, data, condition) {
  if (condition && _H.isPlainObject(data)) {
    $.extend(true, target[key], data);
  } else {
    target[key] = data;
  }
  return target[key];
};


/*
 * Determines whether a propery belongs an object
 *
 * @private
 * @method  isExisted
 * @param   host {Object}   A collection of properties
 * @param   prop {String}   The property to be determined
 * @param   type {String}   Limits property's variable type
 * @return  {Boolean}
 */

isExisted = function(host, prop, type) {
  return _H.isObject(host) && _H.isString(prop) && _H.hasProp(prop, host) && _H.type(host[prop]) === type;
};


/*
 * Determines whether a key in a limited key list
 *
 * @private
 * @method  isLimited
 * @param   key {String}   Key to be determined
 * @param   list {Array}   Limited key list
 * @return  {Boolean}
 */

isLimited = function(key, list) {
  return $.inArray(key, list) > -1;
};


/*
 * 添加到内部存储对象的访问 key 限制列表中
 *
 * @private
 * @method  limit
 * @param   key {String}  Key to be limited
 * @return
 */

limit = function(key) {
  return limiter.key.storage.push(key);
};

_H.mixin({

  /*
   * 自定义警告提示框
   *
   * @method  alert
   * @param   message {String}
   * @param   [callback] {Function}
   * @return  {Boolean}
   */
  alert: function(message, callback) {
    return systemDialog("alert", message, callback);
  },

  /*
   * 自定义确认提示框（两个按钮）
   *
   * @method  confirm
   * @param   message {String}
   * @param   [ok] {Function}       Callback for 'OK' button
   * @param   [cancel] {Function}   Callback for 'CANCEL' button
   * @return  {Boolean}
   */
  confirm: function(message, ok, cancel) {
    return systemDialog("confirm", message, ok, cancel);
  },

  /*
   * 自定义确认提示框（两个按钮）
   *
   * @method  confirm
   * @param   message {String}
   * @param   [ok] {Function}       Callback for 'OK' button
   * @param   [cancel] {Function}   Callback for 'CANCEL' button
   * @return  {Boolean}
   */
  confirmEX: function(message, ok, cancel) {
    return systemDialog("confirmEX", message, ok, cancel);
  },

  /*
   * 将外部处理函数引入到沙盒中
   * 
   * @method  queue
   * @return
   */
  queue: function() {
    return bindHandler.apply(window, this.slice(arguments));
  },

  /*
   * 执行指定函数
   * 
   * @method  run
   * @return  {Variant}
   */
  run: function() {
    return runHandler.apply(window, this.slice(arguments));
  },
  url: function() {
    var loc, url;
    loc = window.location;
    url = {
      search: loc.search.substring(1),
      hash: loc.hash.substring(1),
      query: {}
    };
    this.each(url.search.split("&"), function(str) {
      str = str.split("=");
      if (_H.trim(str[0]) !== "") {
        return url.query[str[0]] = str[1];
      }
    });
    return url;
  },

  /*
   * Save web resource to local disk
   *
   * @method  download
   * @param   fileURL {String}
   * @param   fileName {String}
   * @return
   */
  download: function(fileURL, fileName) {
    var event, save, _window;
    if (!window.ActiveXObject) {
      save = document.createElement("a");
      save.href = fileURL;
      save.target = "_blank";
      save.download = fileName || "unknown";
      event = document.createEvent("Event");
      event.initEvent("click", true, true);
      save.dispatchEvent(event);
      return (window.URL || window.webkitURL).revokeObjectURL(save.href);
    } else if (!!window.ActiveXObject && document.execCommand) {
      _window = window.open(fileURL, "_blank");
      _window.document.close();
      _window.document.execCommand("SaveAs", true, fileName || fileURL);
      return _window.close();
    }
  },

  /*
   * Determines whether a function has been defined
   *
   * @method  functionExists
   * @param   funcName {String}
   * @param   isWindow {Boolean}
   * @return  {Boolean}
   */
  functionExists: function(funcName, isWindow) {
    return isExisted((isWindow === true ? window : storage.fn.handler), funcName, "function");
  }
});


/*
 * 重新配置系统参数
 * 
 * @private
 * @method  resetConfig
 * @param   setting {Object}      配置参数
 * @return  {Object}              （修改后的）系统配置信息
 */

resetConfig = function(setting) {
  return clone(_H.isPlainObject(setting) ? $.extend(storage.config, setting) : storage.config);
};

_H.mixin({

  /*
   * 沙盒
   *
   * 封闭运行环境的开关，每个页面只能运行一次
   * 
   * @method  sandbox
   * @param   setting {Object}      系统环境配置
   * @return  {Object/Boolean}      （修改后的）系统环境配置
   */
  sandbox: function(setting) {
    var result;
    if (storage.sandboxStarted !== true) {
      result = resetConfig(setting);
      runHandler(storage.fn.prepare);
      $(document).ready(function() {
        return runHandler(storage.fn.ready);
      });
      storage.sandboxStarted = true;
    }
    return result || false;
  },

  /*
   * DOM 未加载完时调用的处理函数
   * 主要进行事件委派等与 DOM 加载进程无关的操作
   *
   * @method  prepare
   * @param   handler {Function}
   * @return
   */
  prepare: function(handler) {
    return pushHandler(handler, "prepare");
  },

  /*
   * DOM 加载完成时调用的处理函数
   *
   * @method  ready
   * @param   handler {Function}
   * @return
   */
  ready: function(handler) {
    return pushHandler(handler, "ready");
  }
});


/*
 * 设置初始化函数
 * 
 * @private
 * @method   initialize
 * @return
 */

initialize = function() {
  var args, func, key;
  args = arguments;
  func = args[0];
  key = args[1];
  if (_H.isPlainObject(func)) {
    return _H.each(func, initialize);
  } else if (_H.isString(key) && _H.hasProp(key, storage.fn.init) && _H.isFunction(func)) {
    return storage.fn.init[key] = func;
  }
};


/*
 * 获取 Web API 版本
 * 
 * @private
 * @method   api_ver
 * @return   {String}
 */

api_ver = function() {
  var ver;
  ver = _H.config("api");
  if (_H.isString(ver) && _H.trim(ver) !== "") {
    return "/" + ver;
  } else {
    return "";
  }
};

_H.mixin({

  /*
   * 获取系统信息
   * 
   * @method  config
   * @param   [key] {String}
   * @return  {Object}
   */
  config: function(key) {
    if (this.isString(key)) {
      return storage.config[key];
    } else {
      return clone(storage.config);
    }
  },

  /*
   * 设置初始化信息
   * 
   * @method  init
   * @return
   */
  init: function() {
    return initialize.apply(window, this.slice(arguments));
  },

  /*
   * 设置及获取国际化信息
   * 
   * @method  i18n
   * @return  {String}
   */
  i18n: function() {
    var args, data, key, result;
    args = arguments;
    key = args[0];
    result = null;
    if (this.isPlainObject(key)) {
      $.extend(storage.i18n, key);
    } else if (REG_NAMESPACE.test(key)) {
      data = args[1];
      if (args.length === 2 && this.isString(data) && !REG_NAMESPACE.test(data)) {

      } else if (this.isPlainObject(data)) {
        result = getStorageData("i18n." + key, true);
        result = (this.isString(result) ? result : "").replace(/\{%\s*([A-Z0-9_]+)\s*%\}/ig, (function(_this) {
          return function(txt, k) {
            if (_this.hasProp(k, data)) {
              return data[k];
            } else {
              return "";
            }
          };
        })(this));
      } else {
        result = "";
        this.each(args, function(txt) {
          var r;
          if (_H.isString(txt) && REG_NAMESPACE.test(txt)) {
            r = getStorageData("i18n." + txt, true);
            return result += (_H.isString(r) ? r : "");
          }
        });
      }
    }
    return result;
  },

  /*
   * 设置及获取 Web API
   * 
   * @method  api
   * @return  {String}
   */
  api: function() {
    var args, data, key, match, regexp, result, type, _ref;
    args = arguments;
    key = args[0];
    result = null;
    if (this.isPlainObject(key)) {
      $.extend(storage.web_api, key);
    } else if (this.isString(key)) {
      regexp = /^([a-z]+)_/;
      match = ((_ref = key.match(regexp)) != null ? _ref : [])[1];
      data = args[1];
      type = void 0;
      this.each(["front", "admin"], function(n) {
        if (match === n) {
          type = n;
          return false;
        }
      });
      if (type) {
        key = key.replace(regexp, "");
      } else {
        type = "common";
      }
      result = api_ver() + getStorageData("web_api." + type + "." + key, true);
      if (this.isPlainObject(data)) {
        result = result.replace(/\:([a-z_]+)/g, function(m, k) {
          return data[k];
        });
      }
    }
    return result;
  }
});


/*
 * 通过 HTML 构建 dataset
 * 
 * @private
 * @method  constructDatasetByHTML
 * @param   html {HTML}   Node's outer html string
 * @return  {JSON}
 */

constructDatasetByHTML = function(html) {
  var dataset, fragment;
  dataset = {};
  fragment = html.match(/<[a-z]+[^>]*>/i);
  if (fragment !== null) {
    _H.each(fragment[0].match(/(data(-[a-z]+)+=[^\s>]*)/ig) || [], function(attr) {
      attr = attr.match(/data-(.*)="([^\s"]*)"/i);
      dataset[_H.camelCase(attr[1])] = attr[2];
      return true;
    });
  }
  return dataset;
};


/*
 * 通过属性列表构建 dataset
 * 
 * @private
 * @method  constructDatasetByAttributes
 * @param   attributes {NodeList}   Attribute node list
 * @return  {JSON}
 */

constructDatasetByAttributes = function(attributes) {
  var dataset;
  dataset = {};
  _H.each(attributes, function(attr) {
    var match;
    if (attr.nodeType === ATTRIBUTE_NODE && (match = attr.nodeName.match(/^data-(.*)$/i))) {
      dataset[_H.camelCase(match(1))] = attr.nodeValue;
    }
    return true;
  });
  return dataset;
};

_H.mixin({

  /*
   * 获取 DOM 的「data-*」属性集或存储数据到内部/从内部获取数据
   * 
   * @method  data
   * @return  {Object}
   */
  data: function() {
    var args, error, length, node, result, target;
    args = arguments;
    length = args.length;
    if (length > 0) {
      target = args[0];
      try {
        node = $(target).get(0);
      } catch (_error) {
        error = _error;
        node = target;
      }
      if (node && node.nodeType === ELEMENT_NODE) {
        result = {};
        if (node.dataset) {
          result = node.dataset;
        } else if (node.outerHTML) {
          result = constructDatasetByHTML(node.outerHTML);
        } else if (node.attributes && $.isNumeric(node.attributes.length)) {
          result = constructDatasetByAttributes(node.attributes);
        }
      } else {
        if (this.isString(target) && REG_NAMESPACE.test(target)) {
          result = length === 1 ? getStorageData(target) : setStorageData(target, args[1]);
          if (length > 1 && last(args) === true) {
            limit(target.split(".")[0]);
          }
        }
      }
    }
    return result != null ? result : null;
  },

  /*
   * Save data
   */
  save: function() {
    var args, key, oldVal, val;
    args = arguments;
    key = args[0];
    val = args[1];
    if (support.storage) {
      if (this.isString(key)) {
        oldVal = this.access(key);
        return localStorage.setItem(key, escape(this.isPlainObject(oldVal) ? JSON.stringify($.extend(oldVal, val)) : val));
      }
    }
  },

  /*
   * Access data
   */
  access: function() {
    var error, key, result;
    key = arguments[0];
    if (this.isString(key)) {
      if (support.storage) {
        result = localStorage.getItem(key);
        if (result !== null) {
          result = unescape(result);
          try {
            result = JSON.parse(result);
          } catch (_error) {
            error = _error;
            result = result;
          }
        }
      }
    }
    return result || null;
  }
});


/*
 * AJAX & SJAX 请求处理
 * 
 * @private
 * @method  request
 * @param   options {Object/String}   请求参数列表/请求地址
 * @param   succeed {Function}        请求成功时的回调函数
 * @param   fail {Function}           请求失败时的回调函数
 * @param   synch {Boolean}           是否为同步，默认为异步
 * @return  {Object}
 */

request = function(options, succeed, fail, synch) {
  var handlers;
  if (arguments.length === 0) {
    return;
  }
  if (_H.isPlainObject(options) === false) {
    options = {
      url: options
    };
  }
  handlers = initializer("ajaxHandler")(succeed, fail);
  if (!_H.isFunction(options.success)) {
    options.success = handlers.success;
  }
  if (!_H.isFunction(options.error)) {
    options.error = handlers.error;
  }
  return $.ajax($.extend(options, {
    async: synch !== true
  }));
};

_H.mixin({

  /*
   * Asynchronous JavaScript and XML
   * 
   * @method  ajax
   * @param   options {Object/String}   请求参数列表/请求地址
   * @param   succeed {Function}        请求成功时的回调函数
   * @param   fail {Function}           请求失败时的回调函数
   * @return
   */
  ajax: function(options, succeed, fail) {
    return request(options, succeed, fail);
  },

  /*
   * Synchronous JavaScript and XML
   * 
   * @method  sjax
   * @param   options {Object/String}   请求参数列表/请求地址
   * @param   succeed {Function}        请求成功时的回调函数
   * @param   fail {Function}           请求失败时的回调函数
   * @return
   */
  sjax: function(options, succeed, fail) {
    return request(options, succeed, fail, true);
  }
});

_H.mixin({
  encodeEntities: function(string) {
    if (this.isString(string)) {
      return string.replace(/([<>&\'\"])/, function(match, chr) {
        var et;
        switch (chr) {
          case "<":
            et = lt;
            break;
          case ">":
            et = gt;
            break;
          case "\"":
            et = quot;
            break;
          case "'":
            et = apos;
            break;
          case "&":
            et = amp;
        }
        return "&" + et + ";";
      });
    } else {
      return string;
    }
  },
  decodeEntities: function(string) {}
});

window[LIB_CONFIG.name] = _H;

}));
