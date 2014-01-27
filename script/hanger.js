/*!
 * Hanger - Scaffolding of a project
 * by Ourai Lin, ourairyu@hotmail.coms
 *
 * Full source at https://github.com/ourai/Hanger
 * Copyright (c) 2013 Ourairyu http://ourai.ws/
 */
;(function( window, $, undefined ) {

"use strict";

// Node-types
var ELEMENT_NODE = 1;
var ATTRIBUTE_NODE = 2;
var TEXT_NODE = 3;
var CDATA_SECTION_NODE = 4;
var ENTITY_REFERENCE_NODE = 5;
var ENTITY_NODE = 6;
var PROCESSING_INSTRUCTION_NODE = 7;
var COMMENT_NODE = 8;
var DOCUMENT_NODE = 9;
var DOCUMENT_TYPE_NODE = 10;
var DOCUMENT_FRAGMENT_NODE = 11;
var NOTATION_NODE = 12;

// Save a reference to some core methods
var ls = window.localStorage;

// Regular expressions
var REG_NAMESPACE = /^[0-9A-Z_.]+[^_.]?$/i;

// Normal variables
// var queue = {
//     events: {
//       globalMouseMove: []
//     },
//     callbacks: []
//   };

// Main objects
var _H = {};        // For internal usage

var storage = {
  /**
   * 配置
   */
  config: {
    debug: true,
    platform: "",
    lang: (document.documentElement.lang ||
      document.documentElement.getAttribute("lang") ||
      navigator.language ||
      navigator.browserLanguage).split("-")[0],
    path: currentPath()
  },

  /**
   * 函数
   *
   * @property  fn
   * @type      {Object}
   */
  fn: {
    // 初始化函数
    init: {
      systemDialog: function() {}
    },
    handler: {},
    prepare: [],
    ready: []
  },

  /**
   * 缓冲区，存储临时数据
   *
   * @property  buffer
   * @type      {Object}
   */
  buffer: {},

  /**
   * 对象池
   * 
   * @property  pool
   * @type      {Object}
   */
  pool: {},

  /**
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
  }
};

$.extend( _H, {
/*
 * ======================================
 *  核心方法
 * ======================================
 */
  /**
   * 自定义警告提示框
   *
   * @method  alert
   * @param   message {String}
   * @param   [callback] {Function}
   * @return  {Boolean}
   */
  alert: function( message, callback ) {
    return systemDialog("alert", message, callback);
  },
  
  /**
   * 自定义确认提示框（两个按钮）
   *
   * @method  confirm
   * @param   message {String}
   * @param   [ok] {Function}       Callback for 'OK' button
   * @param   [cancel] {Function}   Callback for 'CANCEL' button
   * @return  {Boolean}
   */
  confirm: function( message, ok, cancel ) {
    return systemDialog("confirm", message, ok, cancel);
  },
  
  /**
   * 自定义确认提示框（两个按钮）
   *
   * @method  confirm
   * @param   message {String}
   * @param   [ok] {Function}       Callback for 'OK' button
   * @param   [cancel] {Function}   Callback for 'CANCEL' button
   * @return  {Boolean}
   */
  confirmEX: function( message, ok, cancel ) {
    return systemDialog("confirmEX", message, ok, cancel);
  },

  /**
   * 设置初始化信息
   * 
   * @method  init
   * @return
   */
  init: function() {
    return initialize.apply(window, [].slice.call(arguments, 0));
  },

  /**
   * 获取系统信息
   * 
   * @method  config
   * @param   [key] {String}
   * @return  {Object}
   */
  config: function( key ) {
    return $.type(key) === "string" ? storage.config[key] : $.extend(true, {}, storage.config);
  },

  /**
   * 沙箱
   * 
   * @method  sandbox
   * @param {Object} setting  系统环境配置
   * @return  {Object}      （修改后的）系统环境配置
   */
  // sandbox: function( setting ) {
  //   return _H.sandbox( setting );
  // },
  
  /**
   * 获取指定的内部数据载体
   * 
   * @method  storage
   * @param {String} name   载体名称
   * @param {Boolean} isCopy  是否返回副本
   * @return  {Object}
   */
  // storage: function( name, isCopy ) {
  //   return _H.getDataset( name, isCopy );
  // },

  /**
   * Asynchronous JavaScript and XML
   * 
   * @method  ajax
   * @param   options {Object/String}   请求参数列表/请求地址
   * @param   succeed {Function}        请求成功时的回调函数（code > 0）
   * @param   fail {Function}           请求失败时的回调函数（code <= 0）
   * @return
   */
  ajax: function( options, succeed, fail ) {
    return request(options, succeed, fail);
  },
  
  /**
   * Synchronous JavaScript and XML
   * 
   * @method  sjax
   * @param   options {Object/String}   请求参数列表/请求地址
   * @param   succeed {Function}        请求成功时的回调函数（code > 0）
   * @param   fail {Function}           请求失败时的回调函数（code <= 0）
   * @return
   */
  sjax: function( options, succeed, fail ) {
    return request(options, succeed, fail, true);
  },
  
  /**
   * 将外部处理函数引入到沙盒中
   * 
   * @method  queue
   * @return
   */
  // queue: function() {
  //   return _H.bindHandler.apply( _H, [].slice.call(arguments, 0) );
  // },
  
  /**
   * 执行指定函数
   * 
   * @method  run
   * @param {String} funcName 函数名
   * @param {List}        函数的参数
   * @return  {Variant}     函数执行的返回值
   */
  // run: function( funcName ) {
  //   return _H.runHandler( funcName, [].slice.call(arguments, 1) );
  // },

  /**
   * 获取 DOM 的「data-*」属性集
   * 
   * @method  data
   * @return  {Object}
   */
  data: function() {
    var args = arguments;
    var length = args.length;
    var result;

    if ( length > 0 ) {
      var target = args[0];
      var node = $(target).get(0);

      // 获取 DOM 的「data-*」属性集
      if ( node && node.nodeType === ELEMENT_NODE ) {
        result = {};

        if ( node.dataset ) {
          result = node.dataset;
        }
        else if ( node.outerHTML ) {
          result = constructDatasetByHTML(node.outerHTML);
        }
        else if ( node.attributes && $.isNumeric(node.attributes.length) ) {
          result = constructDatasetByAttributes(node.attributes);
        }
      }
      // 存储数据到内部/从内部获取数据
      else {
        if ( typeof target === "string" && REG_NAMESPACE.test(target) ) {
          if ( length === 1 ) {
            result = getStorageData(target);
          }
          else if ( $.isPlainObject(args[1]) ) {
            if ( !storage.hasOwnProperty(target) ) {
              storage[target] = args[1];
            }
            else {
              $.extend(storage[target], args[1]);
            }

            result = args[1];
          }
        }
        else {
          $.each(args, function(i, n) {
            $.extend(storage, n);
          });
        }
      }
    }

    return result || null;
  },

  /**
   * 设置及获取国际化信息
   * 
   * @method  i18n
   * @return  {String}
   */
  i18n: function() {
    var args = arguments;
    var key = args[0];
    var result = null;

    // 批量存储
    // 调用方式：func({})
    if ( $.isPlainObject(key) ) {
      $.extend(storage.i18n, key);
    }
    else if ( REG_NAMESPACE.test(key) ) {
      var data = args[1];

      // 单个存储（用 namespace 格式字符串）
      if ( args.length === 2 && typeof data === "string" && !REG_NAMESPACE.test(data) ) {
        // to do sth.
      }
      // 取出并进行格式替换
      else if ( $.isPlainObject(data) ) {
        result = getStorageData("i18n." + key);
        result = (typeof result === "string" ? result : "").replace( /\{%\s*([A-Z0-9_]+)\s*%\}/ig, function( txt, k ) {
          return data[k];
        });
      }
      // 拼接多个数据
      else {
        result = "";

        $.each(args, function(i, txt) {
          if ( typeof txt === "string" && REG_NAMESPACE.test(txt) ) {
            var r = getStorageData("i18n." + txt);

            result += (typeof r === "string" ? r : "");
          }
        });
      }
    }

    return result;
  },

  /**
   * Save data
   */
  save: function() {
    var args = arguments;
    var key = args[0];
    var val = args[1];
    var oldVal;

    // Use localStorage
    if ( ls ) {
      if ( typeof key === "string" ) {
        oldVal = this.access(key);

        ls.setItem(key, escape($.isPlainObject(oldVal) ? JSON.stringify($.extend(oldVal, val)) : val));
      }
    }
    // Use cookie
    else {
      
    }
  },

  /**
   * Access data
   */
  access: function() {
    var key = arguments[0];
    var result;

    if ( typeof key === "string" ) {
      // localStorage
      if ( ls ) {
        result = ls.getItem(key);

        if ( result !== null ) {
          result = unescape(result);

          try {
            result = JSON.parse(result);
          }
          catch (e) {
            result = result;
          }
        }
      }
      // Cookie
      else {

      }
    }

    return result || null;
  },

  url: function() {
    var loc = window.location;
    var url = {
        search: loc.search.substring(1),
        hash: loc.hash.substring(1),
        query: {}
      };

    $.each(url.search.split("&"), function( i, str ) {
      str = str.split("=");

      if ( $.trim(str[0]) !== "" ) {
        url.query[str[0]] = str[1];
      }
    });

    return url;
  },

  /**
   * Save web resource to local disk
   */
  download: function() {
    // for non-IE
    if (!window.ActiveXObject) {
      var save = document.createElement('a');

      save.href = fileURL;
      save.target = '_blank';
      save.download = fileName || 'unknown';

      var event = document.createEvent('Event');
      event.initEvent('click', true, true);
      save.dispatchEvent(event);
      (window.URL || window.webkitURL).revokeObjectURL(save.href);
    }
    // for IE
    else if ( !! window.ActiveXObject && document.execCommand)     {
      var _window = window.open(fileURL, '_blank');
      
      _window.document.close();
      _window.document.execCommand('SaveAs', true, fileName || fileURL)
      _window.close();
    }
  }/*,

  // 把全局事件添加到队列中
  addGlobalEvent: function( event_name, handler ) {
    if ( typeof event_name === "string" && $.isFunction(handler) ) {
      if ( event_name === "mousemove" ) {
        queue.events.globalMouseMove.push( handler );
      }
    }
  }*/
});

/**
 * 获取当前脚本所在目录路径
 * 
 * @private
 * @method  currentPath
 * @return  {String}
 */
function currentPath() {
  var scripts = document.scripts;
  var script = scripts[scripts.length - 1];
  var link = document.createElement("a");

  link.href = script.hasAttribute ? script.src : script.getAttribute("src", 4);

  return link.pathname.replace(/[^\/]+\.js$/i, "");
}

/**
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
function systemDialog( type, message, okHandler, cancelHandler ) {
  var result = false;

  if ( $.type(type) === "string" ) {
    type = type.toLowerCase();

    // jQuery UI Dialog
    if ( $.isFunction($.fn.dialog) ) {
      var poolName = "systemDialog";
      var i18nText = storage.i18n._SYS.dialog[_H.config("lang")];

      if ( !storage.pool.hasOwnProperty(poolName) ) {
        storage.pool[poolName] = {};
      }

      var dlg = storage.pool[poolName][type];

      if ( !dlg ) {
        dlg = $("<div data-role=\"dialog\" data-type=\"system\" />")
          .appendTo($("body"))
          .on({
              // 初始化后的额外处理
              "dialogcreate": storage.fn.init.systemDialog,
              // 为按钮添加标记
              "dialogopen": function( e, ui ) {
                $(".ui-dialog-buttonset .ui-button", $(this).closest(".ui-dialog")).each(function() {
                  var btn = $(this);
                  var type;

                  switch( $.trim( btn.text() ) ) {
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
                      break;
                  }

                  btn.addClass( "ui-button-" + type );
                });
              }
            })
          .dialog({
              "title": i18nText.title,
              "width": 400,
              "minHeight": 100,
              "closeText": i18nText.close,
              "modal": true,
              "autoOpen": false,
              "resizable": false,
              "closeOnEscape": false
            });

        storage.pool[poolName][type] = dlg;

        // 移除关闭按钮
        dlg.closest(".ui-dialog").find(".ui-dialog-titlebar-close").remove();
      }

      result = systemDialogHandler(type, message, okHandler, cancelHandler);
    }
    // 使用 window 提示框
    else {
      result = true;

      if ( type === "alert" ) {
        window.alert(message);
      }
      else {
        if ( window.confirm(message) ) {
          if ( $.isFunction(okHandler) ) {
            okHandler();
          }
        }
        else {
          if ( $.isFunction(cancelHandler) ) {
            cancelHandler();
          }
        }
      }
    }
  }

  return result;
}

/**
 * 系统对话框的提示信息以及按钮处理
 * 
 * @private
 * @method  systemDialogHandler
 * @param   type {String}             对话框类型
 * @param   message {String}          提示信息内容
 * @param   okHandler {Function}      确定按钮
 * @param   cancelHandler {Function}  取消按钮
 */
function systemDialogHandler( type, message, okHandler, cancelHandler ) {
  var i18nText = storage.i18n._SYS.dialog[_H.config("lang")];
  var handler = function( cb, rv ) {
      $(this).dialog("close");

      if ( $.isFunction( cb ) ) {
          cb();
      }

      return rv;
    };

  var btns = [];
  var btnText = {
      "ok": i18nText.ok,
      "cancel": i18nText.cancel,
      "yes": i18nText.yes,
      "no": i18nText.no
    };

  var dlg = storage.pool.systemDialog[type];
  var dlgContent = $("[data-role='dialog-content']", dlg);

  if ( dlgContent.size() === 0 ) {
    dlgContent = dlg;
  }

  // 设置按钮以及其处理函数
  if ( type === "confirm" ) {
    btns.push({
      "text": btnText.ok,
      "click": function() { handler.apply(this, [okHandler, true]); }
    });

    btns.push({
      "text": btnText.cancel,
      "click": function() { handler.apply(this, [cancelHandler, false]); }
    });
  }
  else if ( type === "confirmex" ) {
    btns.push({
      "text": btnText.yes,
      "click": function() { handler.apply(this, [okHandler, true]); }
    });

    btns.push({
      "text": btnText.no,
      "click": function() { handler.apply(this, [cancelHandler, false]); }
    });

    btns.push({
      "text": btnText.cancel,
      "click": function() { handler.apply(this, [null, false]); }
    });
  }
  else {
    type = "alert";

    if ( okHandler !== null ) {
      btns.push({
        "text": btnText.ok,
        "click": function() { handler.apply(this, [okHandler, true]); }
      });
    }
    else {
      btns = null;
    }
  }

  // 提示信息内容
  dlgContent.html(message || "");

  // 添加按钮并打开对话框
  dlg
    .dialog("option", "buttons", btns)
    .dialog("open");
}

/**
 * 设置初始化函数
 * 
 * @private
 * @method  initialize
 * @return
 */
function initialize() {
  var args = arguments;
  var key = args[0];
  var func = args[1];

  if ( $.isPlainObject(key) ) {
    $.each(key, initialize);
  }
  else if ( $.type(key) === "string" && storage.fn.init.hasOwnProperty(key) && $.isFunction(func) ) {
    storage.fn.init[key] = func;
  }
}

/**
 * AJAX & SJAX 请求处理
 *
 * 服务端在返回请求结果时必须是个 JSON，如下：
 *    {
 *      "code": {Integer}       // 处理结果代码，code > 0 为成功，否则为失败
 *      "message": {String}     // 请求失败时的提示信息
 *    }
 * 
 * @private
 * @method  request
 * @param   options {Object/String}   请求参数列表/请求地址
 * @param   succeed {Function}        请求成功时的回调函数（）
 * @param   fail {Function}           请求失败时的回调函数（code <= 0）
 * @param   synch {Boolean}           是否为同步，默认为异步
 * @return  {Object}
 */
function request( options, succeed, fail, synch ) {
  // 无参数时跳出
  if ( arguments.length === 0 ) {
    return;
  }
  
  // 当 options 不是纯对象时将其当作 url 来处理（不考虑其变量类型）
  if ( $.isPlainObject( options ) === false ) {
    options = { url: options };
  }
  
  // 没指定 Ajax 成功回调函数时
  if ( $.isFunction(options.success) === false ) {
    options.success = function( data, textStatus, jqXHR ) {
      if ( data.code > 0 ) {
        if ( $.isFunction(succeed) ) {
          succeed.call($, data, textStatus, jqXHR);
        }
      }
      else {
        if ( $.isFunction(fail) ) {
          fail.call($, data, textStatus, jqXHR);
        }
        // 默认弹出警告对话框
        else {
          systemDialog("alert", data.message);
        }
      }
    };
  }
  
  // synch 为 true 时是同步请求，其他情况则为异步请求
  options.async = synch === true ? false : true;
  
  return $.ajax( options );
}

/**
 * 通过 HTML 构建 dataset
 * 
 * @private
 * @method  constructDatasetByHTML
 * @param   html {HTML}   Node's outer html string
 * @return  {JSON}
 */
function constructDatasetByHTML( html ) {
  var dataset = {};
  var fragment = html.match(/<[a-z]+[^>]*>/i);

  if ( fragment !== null ) {
    $.each( (fragment[0].match( /(data(-[a-z]+)+=[^\s>]*)/ig ) || []), function( idx, attr ) {
      attr = attr.match( /data-(.*)="([^\s"]*)"/i );

      dataset[$.camelCase(attr[1])] = attr[2];
    });
  }

  return dataset;
}

/**
 * 通过属性列表构建 dataset
 * 
 * @private
 * @method  constructDatasetByAttributes
 * @param   attributes {NodeList}   Attribute node list
 * @return  {JSON}
 */
function constructDatasetByAttributes( attributes ) {
  var dataset = {};

  $.each( attributes, function( idx, attr ) {
    var match;

    if ( attr.nodeType === ATTRIBUTE_NODE && (match = attr.nodeName.match( /^data-(.*)$/i )) ) {
      dataset[$.camelCase(match(1))] = attr.nodeValue;
    }
  });

  return dataset;
}

/**
 * Get data from internal storage.
 *
 * @private
 * @method  getStorageData
 * @param   ns_str {String}   Namespace string
 * @return  {String}
 */
function getStorageData( ns_str ) {
  var result = storage;

  $.each(ns_str.split("."), function( idx, part ) {
    var rv = result.hasOwnProperty(part);

    result = result[part];

    return rv;
  });

  return result;
}

// if ( queue.events.globalMouseMove.length ) {
//   $(document).bind({
//     "mousemove": function( e ) {
//       $.each( queue.events.globalMouseMove, function( idx, func ) {
//         func.call(null, e);
//       });
//     }
//   })
// }

window.Hanger = _H;

})( window, window.jQuery );
