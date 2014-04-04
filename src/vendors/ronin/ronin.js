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
var BuiltIn, Constructor, LIB_CONFIG, NAMESPACE_EXP, attach, batch, hasOwnProp, namespace, settings, storage, toString, _H, _builtin;

LIB_CONFIG = {
  name: "Miso",
  version: "0.1.1"
};

toString = {}.toString;

NAMESPACE_EXP = /^[0-9A-Z_.]+[^_.]?$/i;

settings = {
  validator: function() {}
};

storage = {
  core: {},
  types: {},
  modules: {
    Core: {
      BuiltIn: null
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
 * @param    obj {Object}    Target object
 * @param    prop {String}   Property to be tested
 * @return   {Boolean}
 */

hasOwnProp = function(obj, prop) {
  if (obj == null) {
    return false;
  } else {
    return Object.prototype.hasOwnProperty.call(obj, prop);
  }
};


/*
 * 添加命名空间
 *
 * @private
 * @method  namespace
 * @param   ns_str {String}     a namespace format string (e.g. 'Module.Package')
 * @return  {Object}
 */

namespace = function(ns_str) {
  var obj;
  obj = null;
  if (_builtin.isString(ns_str) && NAMESPACE_EXP.test(ns_str)) {
    obj = storage.modules;
    _builtin.each(ns_str.split("."), function(part, idx) {
      if (obj[part] === void 0) {
        obj[part] = {};
      }
      return obj = obj[part];
    });
  }
  return obj;
};


/*
 * 批量添加 method
 *
 * @private
 * @method  batch
 * @param   host {Object}       the host of methods to be added
 * @param   handlers {Object}   data of a method
 * @param   data {Object}       data of a module
 * @return
 */

batch = function(host, handlers, data) {
  var context;
  context = this;
  if (_builtin.isArray(data)) {
    _builtin.each(data, function(d) {
      var _ref;
      return batch.apply(context, [(typeof d[1] === "string" && NAMESPACE_EXP.test(d[1]) ? namespace(d[1]) : host), (_ref = d[0]) != null ? _ref.handlers : void 0, d[0]]);
    });
  } else if (_builtin.isObject(data)) {
    _builtin.each(handlers, function(info) {
      return attach.apply(context, [host, info, data]);
    });
  }
  return true;
};


/*
 * 构造 method
 *
 * @private
 * @method  attach
 * @param   host {Object}       the host of methods to be added
 * @param   set {Object}        data of a method
 * @param   data {Object}       data of a module
 * @param   isCore {Boolean}    whether copy to the core-method-object
 * @return
 */

attach = function(host, set, data) {
  var handler, method, name, validator, validators, value, _i, _len;
  name = set.name;
  if (!_builtin.isFunction(host[name])) {
    handler = set.handler;
    value = hasOwnProp(set, "value") ? set.value : data.value;
    validators = [set.validator, data.validator, settings.validator, function() {}];
    for (_i = 0, _len = validators.length; _i < _len; _i++) {
      validator = validators[_i];
      if (_builtin.isFunction(validator)) {
        break;
      }
    }
    method = function() {
      if (_builtin.isFunction(handler) === true && validator.apply(host, arguments)) {
        return handler.apply(host, arguments);
      } else {
        return value;
      }
    };
    host[name] = method;
  }
  return true;
};

BuiltIn = (function() {
  function BuiltIn() {}


  /*
   * 扩展指定对象
   * 
   * @method  mixin
   * @param   unspecified {Mixed}
   * @return  {Object}
   */

  BuiltIn.prototype.mixin = function() {
    var args, copy, i, length, name, opts, target, _ref;
    args = arguments;
    length = args.length;
    target = (_ref = args[0]) != null ? _ref : {};
    i = 1;
    if (length === 1) {
      target = this;
      i--;
    }
    while (i < length) {
      opts = args[i];
      if (typeof opts === "object") {
        for (name in opts) {
          copy = opts[name];
          if (copy === target) {
            continue;
          }
          if (copy !== void 0) {
            target[name] = copy;
          }
        }
      }
      i++;
    }
    return target;
  };


  /*
   * 遍历
   * 
   * @method  each
   * @param   object {Object/Array/Function}
   * @param   callback {Function}
   * @return  {Mixed}
   */

  BuiltIn.prototype.each = function(object, callback) {
    var ele, index, name, type, value;
    type = this.type(object);
    if (type === "object" || type === "function") {
      for (name in object) {
        value = object[name];
        if (callback.apply(value, [value, name, object]) === false) {
          break;
        }
      }
    } else if (type === "array" || type === "string") {
      index = 0;
      while (index < object.length) {
        ele = type === "array" ? object[index] : object.charAt(index);
        if (callback.apply(object[index], [ele, index++, object]) === false) {
          break;
        }
      }
    }
    return object;
  };


  /*
   * 获取对象类型
   * 
   * @method  type
   * @param   object {Mixed}
   * @return  {String}
   */

  BuiltIn.prototype.type = function(object) {
    if (object == null) {
      return String(object);
    } else {
      return storage.types[toString.call(object)] || "object";
    }
  };


  /*
   * 切割 Array-Like Object 片段
   *
   * @method   slice
   * @param    args {Array-Like}
   * @param    index {Integer}
   * @return
   */

  BuiltIn.prototype.slice = function(args, index) {
    if (args == null) {
      return [];
    } else {
      return [].slice.call(args, Number(index) || 0);
    }
  };


  /*
   * 判断某个对象是否有自己的指定属性
   *
   * @method   hasProp
   * @return   {Boolean}
   */

  BuiltIn.prototype.hasProp = function() {
    return hasOwnProp.apply(this, this.slice(arguments));
  };

  return BuiltIn;

})();

_builtin = new BuiltIn;

_builtin.each("Boolean Number String Function Array Date RegExp Object".split(" "), function(name, i) {
  var lc;
  storage.types["[object " + name + "]"] = lc = name.toLowerCase();
  return _builtin["is" + name] = function(target) {
    return this.type(target) === lc;
  };
});


/*
 * A constructor to construct methods
 *
 * @class   Constructor
 * @constructor
 */

Constructor = (function() {
  function Constructor() {
    var args, data, host, _ref;
    this.constructor = Constructor;
    this.object = {};
    args = arguments;
    data = args[0];
    host = args[1];
    if (args.length < 2 || !((_ref = typeof host) === "object" || _ref === "function")) {
      host = this.object;
    }
    batch.apply(this, [host, data != null ? data.handlers : void 0, data]);
  }

  Constructor.prototype.toString = function() {
    return "[object " + LIB_CONFIG.name + "]";
  };

  Constructor.prototype.add = function(set) {
    return attach(set);
  };

  return Constructor;

})();

_builtin.mixin(Constructor, {
  __builtIn__: _builtin,
  toString: function() {
    return "function " + LIB_CONFIG.name + "() { [native code] }";
  },
  config: function(setting) {
    return _builtin.mixin(settings, setting);
  }
});

_H = Constructor;

window[LIB_CONFIG.name] = _H;

}));

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
var LIB_CONFIG, NAMESPACE_EXP, compareObjects, filterElement, flattenArray, floatLength, func, getMaxMin, ignoreSubStr, isArr, isCollection, name, range, settings, storage, toString, unicode, utf8_to_base64, _H;

LIB_CONFIG = {
  name: "Ronin",
  version: "0.2.1"
};

toString = {}.toString;

NAMESPACE_EXP = /^[0-9A-Z_.]+[^_.]?$/i;

settings = {
  validator: function() {}
};

storage = {
  modules: {
    Core: []
  }
};


/*
 * Compare objects' values or references.
 * 
 * @private
 * @method  compareObjects
 * @param   base {Array/Object}
 * @param   target {Array/Object}
 * @param   strict {Boolean}
 * @param   connate {Boolean}
 * @return  {Boolean}
 */

compareObjects = function(base, target, strict, connate) {
  var isRun, lib, plain, result;
  result = false;
  lib = this;
  plain = lib.isPlainObject(base);
  if ((plain || connate) && strict) {
    result = target === base;
  } else {
    if (plain) {
      isRun = compareObjects.apply(lib, [lib.keys(base), lib.keys(target), false, true]);
    } else {
      isRun = target.length === base.length;
    }
    if (isRun) {
      lib.each(base, function(n, i) {
        var type;
        type = lib.type(n);
        if (lib.inArray(type, ["string", "number", "boolean", "null", "undefined"]) > -1) {
          return result = target[i] === n;
        } else if (lib.inArray(type, ["date", "regexp", "function"]) > -1) {
          return result = strict ? target[i] === n : target[i].toString() === n.toString();
        } else if (lib.inArray(type, ["array", "object"]) > -1) {
          return result = compareObjects.apply(lib, [n, target[i], strict, connate]);
        }
      });
    }
  }
  return result;
};

storage.modules.Core.push([
  {
    validator: function() {
      return true;
    },
    handlers: [
      {

        /*
         * Returns the namespace specified and creates it if it doesn't exist.
         * Be careful when naming packages.
         * Reserved words may work in some browsers and not others.
         *
         * @method  namespace
         * @param   [hostObj] {Object}      Host object namespace will be added to
         * @param   [ns_str_1] {String}     The first namespace string
         * @param   [ns_str_2] {String}     The second namespace string
         * @param   [ns_str_*] {String}     Numerous namespace string
         * @param   [global] {Boolean}      Whether set window as the host object
         * @return  {Object}                A reference to the last namespace object created
         */
        name: "namespace",
        handler: function() {
          var args, hostObj, lib, ns;
          args = arguments;
          lib = this;
          ns = {};
          hostObj = args[0];
          if (!lib.isPlainObject(hostObj)) {
            hostObj = args[args.length - 1] === true ? window : this;
          }
          lib.each(args, function(arg) {
            var obj;
            if (lib.isString(arg) && /^[0-9A-Z_.]+[^_.]$/i.test(arg)) {
              obj = hostObj;
              lib.each(arg.split("."), function(part, idx, parts) {
                if (obj[part] === void 0) {
                  obj[part] = idx === parts.length - 1 ? null : {};
                }
                obj = obj[part];
                return true;
              });
              ns = obj;
            }
            return true;
          });
          return ns;
        }
      }, {

        /*
         * 判断是否为 window 对象
         * 
         * @method  isWindow
         * @param   object {Mixed}
         * @return  {String}
         */
        name: "isWindow",
        handler: function(object) {
          return object && typeof object === "object" && "setInterval" in object;
        }
      }, {

        /*
         * 判断是否为数字类型（字符串）
         * 
         * @method  isNumeric
         * @param   object {Mixed}
         * @return  {Boolean}
         */
        name: "isNumeric",
        handler: function(object) {
          return !isNaN(parseFloat(object)) && isFinite(object);
        }
      }, {

        /*
         * Determine whether a number is an integer.
         *
         * @method  isInteger
         * @param   object {Mixed}
         * @return  {Boolean}
         */
        name: "isInteger",
        handler: function(object) {
          return this.isNumeric(object) && /^-?[1-9]\d*$/.test(object);
        }
      }, {

        /*
         * 判断对象是否为纯粹的对象（由 {} 或 new Object 创建）
         * 
         * @method  isPlainObject
         * @param   object {Mixed}
         * @return  {Boolean}
         */
        name: "isPlainObject",
        handler: function(object) {
          var error, key;
          if (!object || this.type(object) !== "object" || object.nodeType || this.isWindow(object)) {
            return false;
          }
          try {
            if (object.constructor && !this.hasProp(object, "constructor") && !this.hasProp(object.constructor.prototype, "isPrototypeOf")) {
              return false;
            }
          } catch (_error) {
            error = _error;
            return false;
          }
          for (key in object) {
            key;
          }
          return key === void 0 || this.hasProp(object, key);
        }
      }, {

        /*
         * Determin whether a variable is considered to be empty.
         *
         * A variable is considered empty if its value is or like:
         *  - null
         *  - undefined
         *  - false
         *  - ""
         *  - []
         *  - {}
         *  - 0
         *  - 0.0
         *  - "0"
         *  - "0.0"
         *
         * @method  isEmpty
         * @param   object {Mixed}
         * @return  {Boolean}
         *
         * refer: http://www.php.net/manual/en/function.empty.php
         */
        name: "isEmpty",
        handler: function(object) {
          var name, result;
          result = false;
          if ((object == null) || !object) {
            result = true;
          } else if (typeof object === "object") {
            result = true;
            for (name in object) {
              result = false;
              break;
            }
          }
          return result;
        },
        validator: function() {
          return true;
        }
      }, {

        /*
         * 是否为类数组对象
         *
         * @method  isArrayLike
         * @param   object {Mixed}
         * @return  {Boolean}
         */
        name: "isArrayLike",
        handler: function(object) {
          var length, result, type;
          result = false;
          if (typeof object === "object" && object !== null) {
            if (!this.isWindow(object)) {
              type = this.type(object);
              length = object.length;
              if (object.nodeType === 1 && length || type === "array" || type !== "function" && (length === 0 || this.isNumber(length) && length > 0 && (length - 1) in object)) {
                result = true;
              }
            }
          }
          return result;
        }
      }, {

        /*
         * Compares two objects for equality.
         *
         * @method  equal
         * @param   base {Mixed}
         * @param   target {Mixed}
         * @param   strict {Boolean}    whether compares the two objects' references
         * @return  {Boolean}
         */
        name: "equal",
        handler: function(base, target, strict) {
          var connate, lib, plain_b, result, type_b;
          result = false;
          lib = this;
          type_b = lib.type(base);
          if (lib.type(target) === type_b) {
            plain_b = lib.isPlainObject(base);
            if (plain_b && lib.isPlainObject(target) || type_b !== "object") {
              connate = lib.isArray(base);
              if (!plain_b && !connate) {
                base = [base];
                target = [target];
              }
              if (!lib.isBoolean(strict)) {
                strict = false;
              }
              result = compareObjects.apply(lib, [base, target, strict, connate]);
            }
          }
          return result;
        }
      }, {

        /*
         * Returns a random integer between min and max, inclusive.
         * If you only pass one argument, it will return a number between 0 and that number.
         *
         * @method  random
         * @param   min {Number}
         * @param   max {Number}
         * @return  {Number}
         */
        name: "random",
        handler: function(min, max) {
          if (max == null) {
            max = min;
            min = 0;
          }
          return min + Math.floor(Math.random() * (max - min + 1));
        }
      }
    ]
  }
]);

storage.modules.Core.push([
  {
    validator: function() {
      return true;
    },
    handlers: [
      {

        /*
         * Get a set of keys/indexes.
         * It will return a key or an index when pass the 'value' parameter.
         *
         * @method  keys
         * @param   object {Object/Function}    被操作的目标
         * @param   value {Mixed}               指定值
         * @return  {Array/String}
         *
         * refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/keys
         */
        name: "keys",
        handler: function(object, value) {
          var keys;
          keys = [];
          this.each(object, function(v, k) {
            if (v === value) {
              keys = k;
              return false;
            } else {
              return keys.push(k);
            }
          });
          if (this.isArray(keys)) {
            return keys.sort();
          } else {
            return keys;
          }
        },
        validator: function(object) {
          var _ref;
          return object !== null && !(object instanceof Array) && ((_ref = typeof object) === "object" || _ref === "function");
        },
        value: []
      }
    ]
  }
]);


/*
 * Array
 * 
 * Developed by Ourai Lin, http://ourai.ws/
 * 
 * Copyright (c) 2013 JavaScript Revolution
 */


/*
 * Determine whether an object is an array.
 *
 * @private
 * @method  isCollection
 * @param   target {Array/Object}
 * @return  {Boolean}
 */

isArr = function(object) {
  return object instanceof Array;
};


/*
 * Determine whether an object is an array or a plain object.
 *
 * @private
 * @method  isCollection
 * @param   target {Array/Object}
 * @return  {Boolean}
 */

isCollection = function(target) {
  return this.isArray(target) || this.isPlainObject(target);
};


/*
 * Return the maximum (or the minimum) element (or element-based computation).
 * Can't optimize arrays of integers longer than 65,535 elements.
 * See [WebKit Bug 80797](https://bugs.webkit.org/show_bug.cgi?id=80797)
 *
 * @private
 * @method  getMaxMin
 * @param   initialValue {Number}       Default return value of function
 * @param   funcName {String}           Method's name of Math object
 * @param   collection {Array/Object}   A collection to be manipulated
 * @param   callback {Function}         Callback for every element of the collection
 * @param   [context] {Mixed}           Context of the callback
 * @return  {Number}
 */

getMaxMin = function(initialValue, funcName, collection, callback, context) {
  var existCallback, result;
  result = {
    value: initialValue,
    computed: initialValue
  };
  if (isCollection.call(this, collection)) {
    existCallback = this.isFunction(callback);
    if (!existCallback && this.isArray(collection) && collection[0] === +collection[0] && collection.length < 65535) {
      return Math[funcName].apply(Math, collection);
    }
    this.each(collection, function(val, idx, list) {
      var computed;
      computed = existCallback ? callback.apply(context, [val, idx, list]) : val;
      if (funcName === "max" && computed > result.computed || funcName === "min" && computed < result.computed) {
        return result = {
          value: val,
          computed: computed
        };
      }
    });
  }
  return result.value;
};


/*
 * A internal usage to flatten a nested array.
 *
 * @private
 * @method  flattenArray
 * @param   array {Array}
 * @return  {Mixed}
 */

flattenArray = function(array) {
  var arr, lib;
  lib = this;
  arr = [];
  if (lib.isArray(array)) {
    lib.each(array, function(n, i) {
      return arr = arr.concat(flattenArray.call(lib, n));
    });
  } else {
    arr = array;
  }
  return arr;
};


/*
 * 获取小数点后面的位数
 *
 * @private
 * @method  floatLength
 * @param   number {Number}
 * @return  {Integer}
 */

floatLength = function(number) {
  var rfloat;
  rfloat = /^([-+]?\d+)\.(\d+)$/;
  return (rfloat.test(number) ? (number + "").match(rfloat)[2] : "").length;
};


/*
 * Create an array contains specified range.
 *
 * @private
 * @method  range
 * @param   from {Number/String}
 * @param   to {Number/String}
 * @param   step {Number}
 * @param   callback {Function}
 * @return  {Array}
 */

range = function(begin, end, step, callback) {
  var array;
  array = [];
  while (begin <= end) {
    array.push(callback ? callback(begin) : begin);
    begin += step;
  }
  return array;
};


/*
 * Filter elements in a set.
 * 
 * @private
 * @method  filterElement
 * @param   target {Array/Object/String}    operated object
 * @param   callback {Function}             callback to change unit's value
 * @param   context {Mixed}                 context of callback
 * @param   method {Function}               Array's prototype method
 * @param   func {Function}                 callback for internal usage
 * @return  {Array/Object/String}           与被过滤的目标相同类型
 */

filterElement = function(target, callback, context, method, func) {
  var arrOrStr, lib, plainObj, result, _ref;
  result = null;
  lib = this;
  if (lib.isFunction(callback)) {
    arrOrStr = (_ref = lib.type(target)) === "array" || _ref === "string";
    if (context == null) {
      context = window;
    }
    if (lib.isFunction(method) && arrOrStr) {
      result = method.apply(target, [callback, context]);
    } else {
      plainObj = lib.isPlainObject(target);
      if (plainObj) {
        result = {};
      } else if (arrOrStr) {
        result = [];
      }
      if (result !== null) {
        lib.each(target, function(ele, idx) {
          var cbVal;
          cbVal = callback.apply(context, [ele, idx, lib.isString(target) ? new String(target) : target]);
          func(result, cbVal, ele, idx, plainObj, arrOrStr);
          return true;
        });
      }
    }
    if (lib.isString(target)) {
      result = result.join("");
    }
  }
  return result;
};

storage.modules.Core.push([
  {
    value: [],
    validator: function(object) {
      return isArr(object);
    },
    handlers: [
      {

        /*
         * 元素在数组中的位置
         * 
         * @method  inArray
         * @param   element {Mixed}   待查找的数组元素
         * @param   array {Array}     数组
         * @param   from {Integer}    起始索引
         * @return  {Integer}
         */
        name: "inArray",
        handler: function(element, array, from) {
          var index, indexOf, length;
          index = -1;
          indexOf = Array.prototype.indexOf;
          length = array.length;
          from = from ? (from < 0 ? Math.max(0, length + from) : from) : 0;
          if (indexOf) {
            index = indexOf.apply(array, [element, from]);
          } else {
            while (from < length) {
              if (from in array && array[from] === element) {
                index = from;
                break;
              }
              from++;
            }
          }
          return index;
        },
        validator: function(element, array) {
          return isArr(array);
        },
        value: -1
      }, {

        /*
         * 过滤数组、对象
         *
         * @method  filter
         * @param   target {Array/Object/String}    被过滤的目标
         * @param   callback {Function}             过滤用的回调函数
         * @param   [context] {Mixed}               回调函数的上下文
         * @return  {Array/Object/String}           与被过滤的目标相同类型
         *
         * refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/filter
         */
        name: "filter",
        handler: function(target, callback, context) {
          return filterElement.apply(this, [
            target, callback, context, [].filter, function(stack, cbVal, ele, idx, plainObj, arrOrStr) {
              if (cbVal) {
                if (plainObj) {
                  return stack[idx] = ele;
                } else if (arrOrStr) {
                  return stack.push(ele);
                }
              }
            }
          ]);
        },
        validator: function(target) {
          var _ref;
          return isArr(target) || ((_ref = typeof target) === "object" || _ref === "string");
        },
        value: null
      }, {

        /*
         * 改变对象/数组/字符串每个单位的值
         *
         * @method  map
         * @param   target {Array/Object/String}    被操作的目标
         * @param   callback {Function}             改变单位值的回调函数
         * @param   [context] {Mixed}               回调函数的上下文
         * @return  {Array/Object/String}           与被过滤的目标相同类型
         *
         * refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map
         */
        name: "map",
        handler: function(target, callback, context) {
          return filterElement.apply(this, [
            target, callback, context, [].map, function(stack, cbVal, ele, idx, plainObj, arrOrStr) {
              return stack[idx] = cbVal;
            }
          ]);
        },
        validator: function(target) {
          var _ref;
          return isArr(target) || ((_ref = typeof target) === "object" || _ref === "string");
        },
        value: null
      }, {

        /*
         * Calculate product of an array.
         *
         * @method  product
         * @param   array {Array}
         * @return  {Number}
         */
        name: "product",
        handler: function(array) {
          var count, lib, result;
          result = 1;
          count = 0;
          lib = this;
          lib.each(array, function(number, index) {
            if (lib.isNumeric(number)) {
              count++;
              return result *= number;
            }
          });
          if (count === 0) {
            return 0;
          } else {
            return result;
          }
        },
        value: null
      }, {

        /*
         * Remove repeated values.
         * A numeric type string will be converted to number.
         *
         * @method  unique
         * @param   array {Array}
         * @param   last {Boolean}  whether keep the last value
         * @return  {Array}
         */
        name: "unique",
        handler: function(array, last) {
          var lib, result;
          result = [];
          lib = this;
          last = !!last;
          lib.each((last ? array.reverse() : array), function(n, i) {
            if (lib.isNumeric(n)) {
              n = parseFloat(n);
            }
            if (lib.inArray(n, result) === -1) {
              return result.push(n);
            }
          });
          if (last) {
            array.reverse();
            result.reverse();
          }
          return result;
        },
        value: null
      }, {

        /*
         * 建立一个包含指定范围单元的数组
         * 返回数组中从 from 到 to 的单元，包括它们本身。
         * 如果 from > to，则序列将从 to 到 from。
         *
         * @method  range
         * @param   from {Number/String}    起始单元
         * @param   to {Number/String}      终止单元
         * @param   [step] {Number}         单元之间的步进值
         * @return  {Array}
         *
         * refer: http://www.php.net/manual/en/function.range.php
         */
        name: "range",
        handler: function(from, to, step) {
          var callback, decDigit, l_from, l_step, l_to, lib, rCharL, rCharU, result;
          result = [];
          lib = this;
          step = lib.isNumeric(step) && step * 1 > 0 ? step * 1 : 1;
          if (lib.isNumeric(from) && lib.isNumeric(to)) {
            l_from = floatLength(from);
            l_to = floatLength(to);
            l_step = floatLength(step);
            decDigit = Math.max(l_from, l_to, l_step);
            if (decDigit > 0) {
              decDigit = lib.zerofill(1, decDigit + 1) * 1;
              step *= decDigit;
              callback = function(number) {
                return number / decDigit;
              };
            } else {
              decDigit = 1;
            }
            from *= decDigit;
            to *= decDigit;
          } else {
            rCharL = /^[a-z]$/;
            rCharU = /^[A-Z]$/;
            from += "";
            to += "";
            if (rCharL.test(from) && rCharL.test(to) || rCharU.test(from) && rCharU.test(to)) {
              from = from.charCodeAt(0);
              to = to.charCodeAt(0);
              callback = function(code) {
                return String.fromCharCode(code);
              };
            }
          }
          if (lib.isNumber(from) && lib.isNumber(to)) {
            if (from > to) {
              result = range(to, from, step, callback).reverse();
            } else if (from < to) {
              result = range(from, to, step, callback);
            } else {
              result = [callback ? callback(from) : from];
            }
          }
          return result;
        },
        validator: function() {
          return true;
        }
      }, {

        /*
         * Apply a function simultaneously against two values of the 
         * array (default is from left-to-right) as to reduce it to a single value.
         *
         * @method  reduce
         * @param   array {Array}           An array of numeric values to be manipulated.
         * @param   callback {Function}     Function to execute on each value in the array.
         * @param   [initialValue] {Mixed}  Object to use as the first argument to the first call of the callback.
         * @param   [right] {Boolean}       Whether manipulates the array from right-to-left.
         * @return  {Mixed}
         *
         * Callback takes four arguments:
         *  - previousValue
         *          The value previously returned in the last invocation of the callback, or initialValue, if supplied.
         *  - currentValue
         *          The current element being processed in the array.
         *  - index
         *          The index of the current element being processed in the array.
         *  - array
         *          The array reduce was called upon.
         *
         * refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/Reduce
         *        https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/ReduceRight
         */
        name: "reduce",
        handler: function(array, callback, initialValue, right) {
          var args, hasInitVal, index, length, lib, origin, result;
          lib = this;
          right = !!right;
          if (lib.isArray(array)) {
            args = arguments;
            origin = right ? [].reduceRight : [].reduce;
            hasInitVal = args.length > 2;
            if (origin) {
              result = origin.apply(array, hasInitVal ? [callback, initialValue] : [callback]);
            } else {
              index = 0;
              length = array.length;
              if (!hasInitVal) {
                initialValue = array[0];
                index = 1;
                length--;
              }
              if (lib.isFunction(callback)) {
                length = hasInitVal ? length : length + 1;
                while (index < length) {
                  initialValue = callback.apply(window, [initialValue, array[index], index, array]);
                  index++;
                }
                result = initialValue;
              }
            }
          }
          return result;
        },
        value: null
      }, {

        /*
         * Flattens a nested array.
         *
         * @method  flatten
         * @param   array {Array}   a nested array
         * @return  {Array}
         */
        name: "flatten",
        handler: function(array) {
          return flattenArray.call(this, array);
        }
      }, {

        /*
         * Returns a shuffled copy of the list, using a version of the Fisher-Yates shuffle.
         *
         * @method  shuffle
         * @param   target {Mixed}
         * @return  {Array}
         *
         * refer: http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
         */
        name: "shuffle",
        handler: function(target) {
          var index, lib, rand, shuffled;
          lib = this;
          shuffled = [];
          index = 0;
          rand = void 0;
          lib.each(target, function(value) {
            rand = lib.random(index++);
            shuffled[index - 1] = shuffled[rand];
            shuffled[rand] = value;
            return true;
          });
          return shuffled;
        },
        value: null
      }, {

        /*
         * Calculate the sum of values in a collection.
         *
         * @method  sum
         * @param   collection {Array/Object}
         * @return  {Number}
         */
        name: "sum",
        handler: function(collection) {
          var result;
          result = NaN;
          if (isCollection.call(this, collection)) {
            result = 0;
            this.each(collection, function(value) {
              return result += value * 1;
            });
          }
          return result;
        },
        validator: function() {
          return true;
        },
        value: NaN
      }, {

        /*
         * Return the maximum element or (element-based computation).
         *
         * @method  max
         * @param   target {Array/Object}
         * @param   callback {Function}
         * @param   [context] {Mixed}
         * @return  {Number}
         */
        name: "max",
        handler: function(target, callback, context) {
          return getMaxMin.apply(this, [-Infinity, "max", target, callback, (arguments.length < 3 ? window : context)]);
        },
        validator: function() {
          return true;
        }
      }, {

        /*
         * Return the minimum element (or element-based computation).
         *
         * @method  min
         * @param   target {Array/Object}
         * @param   callback {Function}
         * @param   [context] {Mixed}
         * @return  {Number}
         */
        name: "min",
        handler: function(target, callback, context) {
          return getMaxMin.apply(this, [Infinity, "min", target, callback, (arguments.length < 3 ? window : context)]);
        },
        validator: function() {
          return true;
        }
      }
    ]
  }
]);


/*
 * String
 * 
 * Developed by Ourai Lin, http://ourai.ws/
 * 
 * Copyright (c) 2013 JavaScript Revolution
 */


/*
 * Ignore specified strings.
 *
 * @private
 * @method  ignoreSubStr
 * @param   string {String}         The input string. Must be one character or longer.
 * @param   length {Integer}        The number of characters to extract.
 * @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
 * @return  {String}
 */

ignoreSubStr = function(string, length, ignore) {
  var exp, lib, result;
  lib = this;
  exp = lib.isRegExp(ignore) ? ignore : new RegExp(ignore, "ig");
  if (!exp.global) {
    exp = new RegExp(exp.source, "ig");
  }
  result = exp.exec(string);
  while (result) {
    if (result.index < length) {
      length += result[0].length;
    }
    result.lastIndex = 0;
  }
  return string.substring(0, length);
};


/*
 * 将字符串转换为以 \u 开头的十六进制 Unicode
 * 
 * @private
 * @method  unicode
 * @param   string {String}
 * @return  {String}
 */

unicode = function(string) {
  var chr, lib, result;
  lib = this;
  result = [];
  if (lib.isString(string)) {
    result = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = string.length; _i < _len; _i++) {
        chr = string[_i];
        _results.push("\\u" + (lib.pad(Number(chr.charCodeAt(0)).toString(16), 4, '0').toUpperCase()));
      }
      return _results;
    })();
  }
  return result.join("");
};


/*
 * 将 UTF8 字符串转换为 BASE64
 * 
 * @private
 * @method  utf8_to_base64
 * @param   string {String}
 * @return  {String}
 */

utf8_to_base64 = function(string) {
  var atob, btoa, result;
  result = string;
  btoa = window.btoa;
  atob = window.atob;
  if (this.isString(string)) {
    if (this.isFunction(btoa)) {
      result = btoa(unescape(encodeURIComponent(string)));
    }
  }
  return result;
};

storage.modules.Core.push([
  {
    value: "",
    validator: function(object) {
      return this.isString(object);
    },
    handlers: [
      {

        /*
         * 用指定占位符填补字符串
         * 
         * @method  pad
         * @param   string {String}         源字符串
         * @param   length {Integer}        生成字符串的长度，正数为在后面补充，负数则在前面补充
         * @param   placeholder {String}    占位符
         * @return  {String}
         */
        name: "pad",
        handler: function(string, length, placeholder) {
          var index, len, unit;
          if (this.isString(placeholder) === false || placeholder.length !== 1) {
            placeholder = "\x20";
          }
          if (!this.isInteger(length)) {
            length = 0;
          }
          string = String(string);
          index = 1;
          unit = String(placeholder);
          len = Math.abs(length) - string.length;
          if (len > 0) {
            while (index < len) {
              placeholder += unit;
              index++;
            }
            string = length > 0 ? string + placeholder : placeholder + string;
          }
          return string;
        },
        validator: function(string) {
          var _ref;
          return (_ref = typeof string) === "string" || _ref === "number";
        }
      }, {

        /*
         * 将字符串首字母大写
         * 
         * @method  capitalize
         * @param   string {String}     源字符串
         * @param   isAll {Boolean}     是否将所有英文字符串首字母大写
         * @return  {String}
         */
        name: "capitalize",
        handler: function(string, isAll) {
          var exp;
          exp = "[a-z]+";
          return string.replace((isAll === true ? new RegExp(exp, "ig") : new RegExp(exp)), function(c) {
            return c.charAt(0).toUpperCase() + c.slice(1).toLowerCase();
          });
        }
      }, {

        /*
         * 将字符串转换为驼峰式
         * 
         * @method  camelCase
         * @param   string {String}         源字符串
         * @param   is_upper {Boolean}      是否为大驼峰式
         * @return  {String}
         */
        name: "camelCase",
        handler: function(string, is_upper) {
          var firstLetter;
          string = string.toLowerCase().replace(/[-_\x20]([a-z]|[0-9])/ig, function(all, letter) {
            return letter.toUpperCase();
          });
          firstLetter = string.charAt(0);
          string = (is_upper === true ? firstLetter.toUpperCase() : firstLetter.toLowerCase()) + string.slice(1);
          return string;
        }
      }, {

        /*
         * 补零
         * 
         * @method  zerofill
         * @param   number {Number}     源数字
         * @param   digit {Integer}     数字位数，正数为在后面补充，负数则在前面补充
         * @return  {String}
         */
        name: "zerofill",
        handler: function(number, digit) {
          var isFloat, lib, prefix, result, rfloat;
          result = "";
          lib = this;
          rfloat = /^([-+]?\d+)\.(\d+)$/;
          isFloat = rfloat.test(number);
          prefix = "";
          digit = parseInt(digit);
          if (digit > 0 && isFloat) {
            number = (number + "").match(rfloat);
            prefix = "" + (number[1] * 1) + ".";
            number = number[2];
          } else if (number * 1 < 0) {
            prefix = "-";
            number = (number + "").substring(1);
          }
          result = lib.pad(number, digit, "0");
          result = digit < 0 && isFloat ? "" : prefix + result;
          return result;
        },
        validator: function(number, digit) {
          return this.isNumeric(number) && this.isNumeric(digit) && /^-?[1-9]\d*$/.test(digit);
        }
      }, {

        /*
         * Removes whitespace from both ends of the string.
         *
         * @method  trim
         * @param   string {String}
         * @return  {String}
         * 
         * refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/Trim
         */
        name: "trim",
        handler: function(string) {
          var func, rtrim;
          rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g;
          func = "".trim;
          if (func && !func.call("\uFEFF\xA0")) {
            return func.call(string);
          } else {
            return string.replace(rtrim, "");
          }
        }
      }, {

        /*
         * Returns the characters in a string beginning at the specified location through the specified number of characters.
         *
         * @method  substr
         * @param   string {String}         The input string. Must be one character or longer.
         * @param   start {Integer}         Location at which to begin extracting characters.
         * @param   length {Integer}        The number of characters to extract.
         * @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
         * @return  {String}
         * 
         * refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/substr
         */
        name: "substr",
        handler: function(string, start, length, ignore) {
          var args, lib;
          args = arguments;
          lib = this;
          if (args.length === 3 && lib.isNumeric(start) && start > 0 && (lib.isString(length) || lib.isRegExp(length))) {
            string = ignoreSubStr.apply(lib, [string, start, length]);
          } else if (lib.isNumeric(start) && start >= 0) {
            if (!lib.isNumeric(length) || length <= 0) {
              length = string.length;
            }
            string = lib.isString(ignore) || lib.isRegExp(ignore) ? ignoreSubStr.apply(lib, [string.substring(start), length, ignore]) : string.substring(start, length);
          }
          return string;
        }
      }, {

        /*
         * Return information about characters used in a string.
         *
         * Depending on mode will return one of the following:
         *  - 0: an array with the byte-value as key and the frequency of every byte as value
         *  - 1: same as 0 but only byte-values with a frequency greater than zero are listed
         *  - 2: same as 0 but only byte-values with a frequency equal to zero are listed
         *  - 3: a string containing all unique characters is returned
         *  - 4: a string containing all not used characters is returned
         * 
         * @method  countChars
         * @param   string {String}
         * @param   [mode] {Integer}
         * @return  {JSON}
         *
         * refer: http://www.php.net/manual/en/function.count-chars.php
         */
        name: "countChars",
        handler: function(string, mode) {
          var bytes, chars, lib, result;
          result = null;
          lib = this;
          if (!lib.isInteger(mode) || mode < 0) {
            mode = 0;
          }
          bytes = {};
          chars = [];
          lib.each(string, function(chr, idx) {
            var code;
            code = chr.charCodeAt(0);
            if (lib.isNumber(bytes[code])) {
              return bytes[code]++;
            } else {
              bytes[code] = 1;
              if (lib.inArray(chr, chars) < 0) {
                return chars.push(chr);
              }
            }
          });
          switch (mode) {
            case 0:
              break;
            case 1:
              result = bytes;
              break;
            case 2:
              break;
            case 3:
              result = chars.join("");
              break;
            case 4:
              break;
          }
          return result;
        },
        value: null
      }
    ]
  }
]);

storage.modules.Core.push([
  {
    validator: function() {
      return true;
    },
    handlers: (function() {
      var _ref, _results;
      _ref = Miso.__builtIn__;
      _results = [];
      for (name in _ref) {
        func = _ref[name];
        _results.push({
          name: name,
          handler: func
        });
      }
      return _results;
    })()
  }
]);

_H = function() {};

new Miso(storage.modules.Core, _H);

window[LIB_CONFIG.name] = _H;

}));
