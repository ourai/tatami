"use strict";
var $, API, ATTRIBUTE_NODE, CDATA_SECTION_NODE, COMMENT_NODE, DOCUMENT_FRAGMENT_NODE, DOCUMENT_NODE, DOCUMENT_TYPE_NODE, ELEMENT_NODE, ENTITY_NODE, ENTITY_REFERENCE_NODE, I18n, LIB_CONFIG, NOTATION_NODE, PROCESSING_INSTRUCTION_NODE, REG_NAMESPACE, Storage, TEXT_NODE, apiHandler, apiVer, bindHandler, clone, constructDatasetByAttributes, constructDatasetByHTML, getStorageData, initialize, initializer, isExisted, isLimited, last, limit, limiter, pushHandler, request, resetConfig, resolvePathname, route, routeHandler, runHandler, setData, setStorageData, setup, storage, storageHandler, support, systemDialog, systemDialogHandler, _ENV, _H, __proc, __util,
  __slice = [].slice;

LIB_CONFIG = {
  name: "@NAME",
  version: "@VERSION"
};

__proc = (function(window) {
  var attach, batch, defineProp, hasOwnProp, objectTypes, settings, storage, toString;
  toString = {}.toString;
  settings = {
    validator: function() {
      return true;
    }
  };
  storage = {
    types: {}
  };

  /*
   * Fill the map object-types, and add methods to detect object-type.
   * 
   * @private
   * @method   objectTypes
   * @return   {Object}
   */
  objectTypes = function() {
    var type, types, _fn, _i, _len;
    types = "Boolean Number String Function Array Date RegExp Object".split(" ");
    _fn = function(type) {
      var lc;
      storage.types["[object " + type + "]"] = lc = type.toLowerCase();
      return storage.methods["is" + type] = function(target) {
        return this.type(target) === lc;
      };
    };
    for (_i = 0, _len = types.length; _i < _len; _i++) {
      type = types[_i];
      _fn(type);
    }
    return storage.types;
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
   * 为指定 object 或 function 定义属性
   *
   * @private
   * @method   defineProp
   * @param    target {Object}
   * @return   {Boolean}
   */
  defineProp = function(target) {
    var error, prop, value;
    prop = "__" + (LIB_CONFIG.name.toLowerCase()) + "__";
    value = true;
    try {
      Object.defineProperty(target, prop, {
        __proto__: null,
        value: value
      });
    } catch (_error) {
      error = _error;
      target[prop] = value;
    }
    return true;
  };

  /*
   * 批量添加 method
   *
   * @private
   * @method  batch
   * @param   handlers {Object}   data of a method
   * @param   data {Object}       data of a module
   * @param   host {Object}       the host of methods to be added
   * @return
   */
  batch = function(handlers, data, host) {
    var methods;
    methods = storage.methods;
    if (methods.isArray(data) || (methods.isPlainObject(data) && !methods.isArray(data.handlers))) {
      methods.each(data, function(d) {
        return batch(d != null ? d.handlers : void 0, d, host);
      });
    } else if (methods.isPlainObject(data) && methods.isArray(data.handlers)) {
      methods.each(handlers, function(info) {
        return attach(info, data, host);
      });
    }
    return host;
  };

  /*
   * 构造 method
   *
   * @private
   * @method  attach
   * @param   set {Object}        data of a method
   * @param   data {Object}       data of a module
   * @param   host {Object}       the host of methods to be added
   * @return
   */
  attach = function(set, data, host) {
    var handler, method, methods, name, validator, validators, value, _i, _len;
    name = set.name;
    methods = storage.methods;
    if (set.expose !== false && !methods.isFunction(host[name])) {
      handler = set.handler;
      value = hasOwnProp(set, "value") ? set.value : data.value;
      validators = [
        set.validator, data.validator, settings.validator, function() {
          return true;
        }
      ];
      for (_i = 0, _len = validators.length; _i < _len; _i++) {
        validator = validators[_i];
        if (methods.isFunction(validator)) {
          break;
        }
      }
      method = function() {
        if (methods.isFunction(handler) && validator.apply(host, arguments) === true) {
          return handler.apply(host, arguments);
        } else {
          return value;
        }
      };
      host[name] = method;
    }
    return host;
  };
  storage.methods = {

    /*
     * 扩展指定对象
     * 
     * @method  mixin
     * @param   unspecified {Mixed}
     * @return  {Object}
     */
    mixin: function() {
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
    },

    /*
     * 遍历
     * 
     * @method  each
     * @param   object {Object/Array/Array-Like/Function/String}
     * @param   callback {Function}
     * @return  {Mixed}
     */
    each: function(object, callback) {
      var ele, index, name, value;
      if (this.isArray(object) || this.isArrayLike(object) || this.isString(object)) {
        index = 0;
        while (index < object.length) {
          ele = this.isString(object) ? object.charAt(index) : object[index];
          if (callback.apply(ele, [ele, index++, object]) === false) {
            break;
          }
        }
      } else if (this.isObject(object) || this.isFunction(object)) {
        for (name in object) {
          value = object[name];
          if (callback.apply(value, [value, name, object]) === false) {
            break;
          }
        }
      }
      return object;
    },

    /*
     * 获取对象类型
     * 
     * @method  type
     * @param   object {Mixed}
     * @return  {String}
     */
    type: function(object) {
      if (object == null) {
        return String(object);
      } else {
        return storage.types[toString.call(object)] || "object";
      }
    },

    /*
     * 切割 Array-Like Object 片段
     *
     * @method   slice
     * @param    args {Array-Like}
     * @param    index {Integer}
     * @return
     */
    slice: function(args, index) {
      if (args == null) {
        return [];
      } else {
        return [].slice.call(args, Number(index) || 0);
      }
    },

    /*
     * 判断某个对象是否有自己的指定属性
     *
     * @method   hasProp
     * @param    prop {String}   Property to be tested
     * @param    obj {Object}    Target object
     * @return   {Boolean}
     */
    hasProp: function(prop, obj) {
      return hasOwnProp.apply(this, [(arguments.length < 2 ? window : obj), prop]);
    },

    /*
     * 判断是否为 window 对象
     * 
     * @method  isWindow
     * @param   object {Mixed}
     * @return  {Boolean}
     */
    isWindow: function(object) {
      return object && this.isObject(object) && "setInterval" in object;
    },

    /*
     * 判断是否为 DOM 对象
     * 
     * @method  isElement
     * @param   object {Mixed}
     * @return  {Boolean}
     */
    isElement: function(object) {
      return object && this.isObject(object) && object.nodeType === 1;
    },

    /*
     * 判断是否为数字类型（字符串）
     * 
     * @method  isNumeric
     * @param   object {Mixed}
     * @return  {Boolean}
     */
    isNumeric: function(object) {
      return !isNaN(parseFloat(object)) && isFinite(object);
    },

    /*
     * Determine whether a number is an integer.
     *
     * @method  isInteger
     * @param   object {Mixed}
     * @return  {Boolean}
     */
    isInteger: function(object) {
      return this.isNumeric(object) && /^-?[1-9]\d*$/.test(object);
    },

    /*
     * 判断对象是否为纯粹的对象（由 {} 或 new Object 创建）
     * 
     * @method  isPlainObject
     * @param   object {Mixed}
     * @return  {Boolean}
     */
    isPlainObject: function(object) {
      var error, key;
      if (!object || !this.isObject(object) || object.nodeType || this.isWindow(object)) {
        return false;
      }
      try {
        if (object.constructor && !this.hasProp("constructor", object) && !this.hasProp("isPrototypeOf", object.constructor.prototype)) {
          return false;
        }
      } catch (_error) {
        error = _error;
        return false;
      }
      for (key in object) {
        key;
      }
      return key === void 0 || this.hasProp(key, object);
    },

    /*
     * Determin whether a variable is considered to be empty.
     *
     * A variable is considered empty if its value is or like:
     *  - null
     *  - undefined
     *  - ""
     *  - []
     *  - {}
     *
     * @method  isEmpty
     * @param   object {Mixed}
     * @return  {Boolean}
     *
     * refer: http://www.php.net/manual/en/function.empty.php
     */
    isEmpty: function(object) {
      var name, result;
      result = false;
      if ((object == null) || object === "") {
        result = true;
      } else if ((this.isArray(object) || this.isArrayLike(object)) && object.length === 0) {
        result = true;
      } else if (this.isObject(object)) {
        result = true;
        for (name in object) {
          result = false;
          break;
        }
      }
      return result;
    },

    /*
     * 是否为类数组对象
     *
     * 类数组对象（Array-Like Object）是指具备以下特征的对象：
     * -
     * 1. 不是数组（Array）
     * 2. 有自动增长的 length 属性
     * 3. 以从 0 开始的数字做属性名
     *
     * @method  isArrayLike
     * @param   object {Mixed}
     * @return  {Boolean}
     */
    isArrayLike: function(object) {
      var length, result;
      result = false;
      if (this.isObject(object) && object !== null) {
        if (!this.isWindow(object)) {
          length = object.length;
          if (object.nodeType === 1 && length || !this.isArray(object) && !this.isFunction(object) && (length === 0 || this.isNumber(length) && length > 0 && (length - 1) in object)) {
            result = true;
          }
        }
      }
      return result;
    }
  };
  objectTypes();
  __proc = function(data, host) {
    return batch(data != null ? data.handlers : void 0, data, host != null ? host : {});
  };
  storage.methods.each(storage.methods, function(handler, name) {
    return __proc[name] = handler;
  });
  return __proc;
})(window);

__util = (function(window, __proc) {
  var DateTimeFormats, DateTimeNames, ISOstr2date, NAMESPACE_EXP, UTCstr2date, compareObjects, dateStr2obj, dtwz, error, filterElement, flattenArray, floatLength, formatDate, func, getMaxMin, ignoreSubStr, isArr, isCollection, name, range, storage, stringifyCollection, timezoneOffset, toString, unicode, utf8_to_base64;
  toString = {}.toString;
  NAMESPACE_EXP = /^[0-9A-Z_.]+[^_.]?$/i;
  storage = {
    regexps: {
      date: {
        iso8601: /^(\d{4})\-(\d{2})\-(\d{2})(?:T(\d{2})\:(\d{2})\:(\d{2})(?:(?:\.)(\d{3}))?(Z|[+-]\d{2}\:\d{2})?)?$/
      },
      object: {
        array: /\[(.*)\]/,
        number: /(-?[0-9]+)/
      }
    },
    modules: {
      Core: {}
    }
  };
  storage.modules.Core.BuiltIn = {
    handlers: (function() {
      var _results;
      _results = [];
      for (name in __proc) {
        func = __proc[name];
        _results.push({
          name: name,
          handler: func
        });
      }
      return _results;
    })()
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

  /*
   * 将 Array、Object 转化为字符串
   * 
   * @private
   * @method  stringifyCollection
   * @param   collection {Array/Plain Object}
   * @return  {String}
   */
  stringifyCollection = function(collection) {
    var ele, key, stack, val;
    if (this.isArray(collection)) {
      stack = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = collection.length; _i < _len; _i++) {
          ele = collection[_i];
          _results.push(this.stringify(ele));
        }
        return _results;
      }).call(this);
    } else {
      stack = (function() {
        var _results;
        _results = [];
        for (key in collection) {
          val = collection[key];
          _results.push("\"" + key + "\":" + (this.stringify(val)));
        }
        return _results;
      }).call(this);
    }
    return stack.join(",");
  };
  storage.modules.Core.Global = {
    handlers: [
      {

        /*
         * 扩充对象
         * 
         * @method   extend
         * @param    data {Plain Object/Array}
         * @param    host {Object}
         * @return   {Object}
         */
        name: "extend",
        handler: function(data, host) {
          return __proc(data, host);
        }
      }, {

        /*
         * 别名
         * 
         * @method  alias
         * @param   name {String}
         * @return
         */
        name: "alias",
        handler: function(name) {
          if (this.isString(name)) {
            if (window[name] === void 0) {
              window[name] = this;
            }
          }
          return window[String(name)];
        }
      }, {

        /*
         * 更改 LIB_CONFIG.name
         * 
         * @method   mask
         * @param    guise {String}    New name for library
         * @return   {Boolean}
         */
        name: "mask",
        handler: function(guise) {
          var error, lib_name, result;
          if (this.hasProp(guise)) {
            if (window.console) {
              console.error("'" + guise + "' has existed as a property of Window object.");
            }
          } else {
            lib_name = this.__meta__.name;
            window[guise] = window[lib_name];
            try {
              result = delete window[lib_name];
            } catch (_error) {
              error = _error;
              window[lib_name] = void 0;
              result = true;
            }
            this.__meta__.name = guise;
          }
          return result;
        },
        validator: function(guise) {
          return this.isString(guise);
        },
        value: false
      }, {

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
         * @param   [isGlobal] {Boolean}    Whether set window as the host object
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
      }, {

        /*
         * 字符串化
         *
         * @method  stringify
         * @param   target {Variant}
         * @return  {String}
         */
        name: "stringify",
        handler: function(target) {
          var e, result, t;
          t = this.type(target);
          if (t === "object") {
            if (this.isPlainObject(target)) {
              try {
                result = JSON.stringify(target);
              } catch (_error) {
                e = _error;
                result = "{" + (stringifyCollection.call(this, target)) + "}";
              }
            } else {
              result = "";
            }
          } else {
            switch (t) {
              case "array":
                result = "[" + (stringifyCollection.call(this, target)) + "]";
                break;
              case "function":
              case "date":
              case "regexp":
                result = target.toString();
                break;
              case "string":
                result = "\"" + target + "\"";
                break;
              default:
                try {
                  result = String(target);
                } catch (_error) {
                  e = _error;
                  result = "";
                }
            }
          }
          return result;
        }
      }, {
        name: "parse",
        handler: function(target) {
          var result;
          target = this.trim(target);
          result = target;
          this.each(storage.regexps.object, (function(_this) {
            return function(r, o) {
              var re_c, re_g, re_t;
              re_t = new RegExp("^" + r.source + "$");
              if (re_t.test(target)) {
                switch (o) {
                  case "array":
                    re_g = new RegExp("" + r.source, "g");
                    re_c = /(\[.*\])/;
                    r = re_g.exec(target);
                    result = [];
                    while (r != null) {
                      _this.each(r[1].split(","), function(unit, idx) {
                        return result.push(_this.parse(unit));
                      });
                      break;
                    }
                    break;
                  case "number":
                    result *= 1;
                }
                return false;
              } else {
                return true;
              }
            };
          })(this));
          return result;
        },
        validator: function(target) {
          return this.isString(target);
        },
        value: "",
        expose: false
      }
    ]
  };
  storage.modules.Core.Object = {
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
  };

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
  storage.modules.Core.Array = {
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
  };

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
  storage.modules.Core.String = {
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
          var rtrim;
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
  };

  /*
   * 将日期字符串转化为日期对象
   *
   * @private
   * @method   dateStr2obj
   * @param    date_str {String}
   * @return   {Date}
   */
  dateStr2obj = function(date_str) {
    var date, date_parts;
    date_str = this.trim(date_str);
    date = new Date(date_str);
    if (isNaN(date.getTime())) {
      date_parts = date_str.match(storage.regexps.date.iso8601);
      date = date_parts != null ? ISOstr2date.call(this, date_parts) : new Date;
    }
    return date;
  };

  /*
   * ISO 8601 日期字符串转化为日期对象
   *
   * @private
   * @method   ISOstr2date
   * @param    date_parts {Array}
   * @return   {Date}
   */
  ISOstr2date = function(date_parts) {
    var date, tz_offset;
    date_parts.shift();
    date = UTCstr2date.call(this, date_parts);
    tz_offset = timezoneOffset(date_parts.slice(-1)[0]);
    if (tz_offset !== 0) {
      date.setTime(date.getTime() - tz_offset);
    }
    return date;
  };

  /*
   * 转化为 UTC 日期对象
   *
   * @private
   * @method   UTCstr2date
   * @param    date_parts {Array}
   * @return   {Date}
   */
  UTCstr2date = function(date_parts) {
    var date, handlers;
    handlers = ["FullYear", "Month", "Date", "Hours", "Minutes", "Seconds", "Milliseconds"];
    date = new Date;
    this.each(date_parts, function(ele, i) {
      var handler;
      if ((ele != null) && ele !== "") {
        handler = handlers[i];
        if (handler != null) {
          return date["setUTC" + handler](ele * 1 + (handler === "Month" ? -1 : 0));
        }
      }
    });
    return date;
  };

  /*
   * 相对于 UTC 的偏移值
   *
   * @private
   * @method   timezoneOffset
   * @param    timezone {String}
   * @return   {Integer}
   */
  timezoneOffset = function(timezone) {
    var cap, offset;
    offset = 0;
    if (/^(Z|[+-]\d{2}\:\d{2})$/.test(timezone)) {
      cap = timezone.charAt(0);
      if (cap !== "Z") {
        offset = timezone.substring(1).split(":");
        offset = (cap + (offset[0] * 60 + offset[1] * 1)) * 60 * 1000;
      }
    }
    return offset;
  };
  DateTimeNames = {
    month: {
      long: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
      short: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    },
    week: {
      long: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thurday", "Friday", "Saturday"],
      short: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
  };
  DateTimeFormats = {
    "d": function(date) {
      return dtwz.call(this, date.getDate());
    },
    "D": function(date) {
      return DateTimeNames.week.short[date.getDay()];
    },
    "j": function(date) {
      return date.getDate();
    },
    "l": function(date) {
      return DateTimeNames.week.long[date.getDay()];
    },
    "N": function(date) {
      var day;
      day = date.getDay();
      if (day === 0) {
        day = 7;
      }
      return day;
    },
    "S": function(date) {
      var suffix;
      switch (String(date.getDate()).slice(-1)) {
        case "1":
          suffix = "st";
          break;
        case "2":
          suffix = "nd";
          break;
        case "3":
          suffix = "rd";
          break;
        default:
          suffix = "th";
      }
      return suffix;
    },
    "w": function(date) {
      return date.getDay();
    },
    "F": function(date) {
      return DateTimeNames.month.long[date.getMonth()];
    },
    "m": function(date) {
      return dtwz.call(this, DateTimeFormats.n.call(this, date));
    },
    "M": function(date) {
      return DateTimeNames.month.short[date.getMonth()];
    },
    "n": function(date) {
      return date.getMonth() + 1;
    },
    "Y": function(date) {
      return date.getFullYear();
    },
    "y": function(date) {
      return String(date.getFullYear()).slice(-2);
    },
    "a": function(date) {
      var h;
      h = date.getHours();
      if ((0 < h && h < 12)) {
        return "am";
      } else {
        return "pm";
      }
    },
    "A": function(date) {
      return DateTimeFormats.a.call(this, date).toUpperCase();
    },
    "g": function(date) {
      var h;
      h = date.getHours();
      if (h === 0) {
        h = 24;
      }
      if (h > 12) {
        return h - 12;
      } else {
        return h;
      }
    },
    "G": function(date) {
      return date.getHours();
    },
    "h": function(date) {
      return dtwz.call(this, DateTimeFormats.g.call(this, date));
    },
    "H": function(date) {
      return dtwz.call(this, DateTimeFormats.G.call(this, date));
    },
    "i": function(date) {
      return dtwz.call(this, date.getMinutes());
    },
    "s": function(date) {
      return dtwz.call(this, date.getSeconds());
    }
  };

  /*
   * 添加前导“0”
   *
   * @private
   * @method   dtwz
   * @param    datetime {Integer}
   * @return   {String}
   */
  dtwz = function(datetime) {
    return this.pad(datetime, -2, "0");
  };

  /*
   * 格式化日期
   *
   * @private
   * @method   formatDate
   * @param    format {String}
   * @param    date {Date}
   * @return   {String}
   */
  formatDate = function(format, date) {
    var context, formatted;
    if (!this.isDate(date) || isNaN(date.getTime())) {
      date = new Date;
    }
    context = this;
    formatted = format.replace(new RegExp("([a-z]|\\\\)", "gi"), function() {
      var handler, m, o, p, s, _i;
      m = arguments[0], p = 4 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 2) : (_i = 1, []), o = arguments[_i++], s = arguments[_i++];
      if (m === "\\") {
        return "";
      } else {
        if (s.charAt(o - 1) !== "\\") {
          handler = DateTimeFormats[m];
        }
      }
      if (handler != null) {
        return handler.call(context, date);
      } else {
        return m;
      }
    });
    return formatted;
  };
  storage.modules.Core.Date = {
    handlers: [
      {

        /*
         * 格式化日期对象/字符串
         *
         * format 参照 PHP：
         *   http://www.php.net/manual/en/function.date.php
         * 
         * @method  date
         * @param   format {String}
         * @param   [date] {Date/String}
         * @return  {String}
         */
        name: "date",
        handler: function(format, date) {
          if (this.isString(date)) {
            date = dateStr2obj.call(this, date);
          }
          return formatDate.apply(this, [format, date]);
        },
        value: "",
        validator: function(format) {
          return this.isString(format);
        }
      }, {

        /*
         * 取得当前时间
         *
         * @method   now
         * @param    [is_object] {Boolean}
         * @return   {Integer/Date}
         */
        name: "now",
        handler: function(is_object) {
          var date;
          date = new Date;
          if (is_object === true) {
            return date;
          } else {
            return date.getTime();
          }
        }
      }
    ]
  };
  __util = __proc(storage.modules);
  try {
    Object.defineProperty(__util, "__meta__", {
      __proto__: null,
      writable: true,
      value: {
        name: "__util",
        version: ""
      }
    });
  } catch (_error) {
    error = _error;
    __util.mixin({
      __meta__: {
        name: "__util",
        version: ""
      }
    });
  }
  return __util;
})(window, __proc);

Storage = (function(__util) {
  var getData, hasProp, isNamespaceStr, isPlainObj, storage, str2obj;
  hasProp = __util.hasProp;
  isPlainObj = __util.isPlainObject;
  storage = {};
  isNamespaceStr = function(str) {
    return /^[0-9a-z_.]+[^_.]?$/i.test(str);
  };
  str2obj = function(str) {
    var obj;
    obj = storage;
    __util.each(str.split("."), function(part) {
      if (!hasProp(part, obj)) {
        obj[part] = {};
      }
      return obj = obj[part];
    });
    return obj;
  };
  getData = function(host, key, map) {
    var keys, result, s;
    __util.each(key.split("."), function(part) {
      var r;
      r = hasProp(part, host);
      host = host[part];
      return r;
    });
    s = this.settings;
    if (!isPlainObj(map)) {
      map = {};
    }
    keys = isPlainObj(s.keys) ? s.keys : {};
    result = s.value(host).replace(s.format_regexp, (function(_this) {
      return function(m, k) {
        var r;
        if (hasProp(k, map)) {
          r = map[k];
        } else if (hasProp(k, keys)) {
          r = keys[k];
        } else {
          r = m;
        }
        return r;
      };
    })(this));
    return result;
  };
  Storage = (function() {
    function Storage(namespace) {
      this.settings = {
        format_regexp: /.*/g,
        allow_keys: false,
        keys: {},
        value: function(v) {
          return v != null ? v : "";
        }
      };
      this.storage = isNamespaceStr(namespace) ? str2obj("" + namespace) : storage;
    }

    Storage.prototype.set = function(data) {
      return __util.mixin(this.storage, data);
    };

    Storage.prototype.get = function(key, map) {
      var data;
      if (__util.isString(key)) {
        data = getData.apply(this, [this.storage, key, map]);
      } else if (this.settings.allow_keys === true) {
        data = __util.keys(this.storage);
      }
      return data != null ? data : null;
    };

    Storage.prototype.config = function(settings) {
      return __util.mixin(this.settings, settings);
    };

    return Storage;

  })();
  return Storage;
})(__util);

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

_H = __util;

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
    storage: ["sandboxStarted", "config", "fn", "buffer", "pool", "i18n"]
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
  modules: {
    utils: {},
    flow: {},
    project: {},
    storage: {},
    request: {},
    HTML: {},
    URL: {}
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
  }
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

storage.modules.utils = {
  handlers: [
    {

      /*
       * 自定义警告提示框
       *
       * @method  alert
       * @param   message {String}
       * @param   [callback] {Function}
       * @return  {Boolean}
       */
      name: "alert",
      handler: function(message, callback) {
        return systemDialog("alert", message, callback);
      }
    }, {

      /*
       * 自定义确认提示框（两个按钮）
       *
       * @method  confirm
       * @param   message {String}
       * @param   [ok] {Function}       Callback for 'OK' button
       * @param   [cancel] {Function}   Callback for 'CANCEL' button
       * @return  {Boolean}
       */
      name: "confirm",
      handler: function(message, ok, cancel) {
        return systemDialog("confirm", message, ok, cancel);
      }
    }, {

      /*
       * 自定义确认提示框（两个按钮）
       *
       * @method  confirm
       * @param   message {String}
       * @param   [ok] {Function}       Callback for 'OK' button
       * @param   [cancel] {Function}   Callback for 'CANCEL' button
       * @return  {Boolean}
       */
      name: "confirmEX",
      handler: function(message, ok, cancel) {
        return systemDialog("confirmEX", message, ok, cancel);
      }
    }, {

      /*
       * 将外部处理函数引入到沙盒中
       * 
       * @method  queue
       * @return
       */
      name: "queue",
      handler: function() {
        return bindHandler.apply(window, this.slice(arguments));
      }
    }, {

      /*
       * 执行指定函数
       * 
       * @method  run
       * @return  {Variant}
       */
      name: "run",
      handler: function() {
        return runHandler.apply(window, this.slice(arguments));
      }
    }, {
      name: "url",
      handler: function() {
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
      }
    }, {

      /*
       * Save web resource to local disk
       *
       * @method  download
       * @param   fileURL {String}
       * @param   fileName {String}
       * @return
       */
      name: "download",
      handler: function(fileURL, fileName) {
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
      }
    }, {

      /*
       * Determines whether a function has been defined
       *
       * @method  functionExists
       * @param   funcName {String}
       * @param   isWindow {Boolean}
       * @return  {Boolean}
       */
      name: "functionExists",
      handler: function(funcName, isWindow) {
        return isExisted((isWindow === true ? window : storage.fn.handler), funcName, "function");
      }
    }
  ]
};


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

storage.modules.flow = {
  handlers: [
    {

      /*
       * 沙盒
       *
       * 封闭运行环境的开关，每个页面只能运行一次
       * 
       * @method  sandbox
       * @param   setting {Object}      系统环境配置
       * @return  {Object/Boolean}      （修改后的）系统环境配置
       */
      name: "sandbox",
      handler: function(setting) {
        var result;
        result = resetConfig(setting);
        runHandler(storage.fn.prepare);
        $(document).ready(function() {
          return runHandler(storage.fn.ready);
        });
        storage.sandboxStarted = true;
        return result || false;
      },
      value: false,
      validator: function() {
        return storage.sandboxStarted !== true;
      }
    }, {

      /*
       * DOM 未加载完时调用的处理函数
       * 主要进行事件委派等与 DOM 加载进程无关的操作
       *
       * @method  prepare
       * @param   handler {Function}
       * @return
       */
      name: "prepare",
      handler: function(handler) {
        return pushHandler(handler, "prepare");
      }
    }, {

      /*
       * DOM 加载完成时调用的处理函数
       *
       * @method  ready
       * @param   handler {Function}
       * @return
       */
      name: "ready",
      handler: function(handler) {
        return pushHandler(handler, "ready");
      }
    }
  ]
};

storage.web_api = {};

storage.config.api = "";

storage.fn.init.apiNS = function(key) {};

I18n = new Storage("I18n");

I18n.config({
  format_regexp: /\{%\s*([A-Z0-9_]+)\s*%\}/ig,
  value: function(val) {
    if (_H.isString(val)) {
      return val;
    } else {
      return "";
    }
  }
});

API = new Storage("Web_API");

API.config({
  format_regexp: /\:([a-z_]+)/g,
  value: function(val) {
    var _ref;
    return (_ref = apiVer() + val) != null ? _ref : "";
  }
});

route = new Storage("route");

route.config({
  format_regexp: /\:([a-z_]+)/g
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
 * @method   apiVer
 * @return   {String}
 */

apiVer = function() {
  var ver;
  ver = _H.config("api");
  if (_H.isString(ver) && _H.trim(ver) !== "") {
    return "/" + ver;
  } else {
    return "";
  }
};

storageHandler = function(type, key, map) {
  var getKey, result;
  switch (type) {
    case "api":
      storage = API;
      getKey = function(k) {
        var _ref;
        return (_ref = initializer("apiNS")(k)) != null ? _ref : k;
      };
      break;
    case "route":
      storage = route;
  }
  if (this.isPlainObject(key)) {
    storage.set(key);
  } else if (this.isString(key)) {
    result = storage.get((getKey != null ? getKey() : key), map);
  }
  return result != null ? result : null;
};

apiHandler = function(key, map) {
  return storageHandler("api", key, map);
};

apiHandler.formatList = function(map) {
  if (_H.isPlainObject(map)) {
    return API.config({
      keys: map
    });
  }
};

routeHandler = function(key, map) {
  return storageHandler("route", key, map);
};

routeHandler.formatList = function(map) {
  if (_H.isPlainObject(map)) {
    return route.config({
      keys: map
    });
  }
};

storage.modules.project = {
  handlers: [
    {

      /*
       * 获取系统信息
       * 
       * @method  config
       * @param   [key] {String}
       * @return  {Object}
       */
      name: "config",
      handler: function(key) {
        if (this.isString(key)) {
          return storage.config[key];
        } else {
          return clone(storage.config);
        }
      }
    }, {

      /*
       * 设置初始化信息
       * 
       * @method  init
       * @return
       */
      name: "init",
      handler: function() {
        return initialize.apply(window, this.slice(arguments));
      }
    }, {

      /*
       * 设置及获取国际化信息
       * 
       * @method   i18n
       * @param    key {String}
       * @param    [map] {Plain Object}
       * @return   {String}
       */
      name: "i18n",
      handler: function(key, map) {
        var args, result;
        args = arguments;
        if (this.isPlainObject(key)) {
          I18n.set(key);
        } else if (REG_NAMESPACE.test(key)) {
          if (args.length === 2 && this.isString(map) && !REG_NAMESPACE.test(map)) {

          } else {
            if (this.isPlainObject(map)) {
              result = I18n.get(key, map);
            } else {
              result = "";
              this.each(args, function(txt) {
                if (_H.isString(txt) && REG_NAMESPACE.test(txt)) {
                  return result += I18n.get(txt);
                }
              });
            }
          }
        }
        return result != null ? result : null;
      }
    }, {

      /*
       * 设置及获取 Web API
       * 
       * @method   api
       * @param    key {String}
       * @param    [map] {Plain Object}
       * @return   {String}
       */
      name: "api",
      handler: apiHandler
    }, {
      name: "route",
      handler: routeHandler
    }
  ]
};


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

storage.modules.storage = {
  handlers: [
    {

      /*
       * 获取 DOM 的「data-*」属性集或存储数据到内部/从内部获取数据
       * 
       * @method  data
       * @return  {Object}
       */
      name: "data",
      handler: function() {
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
      }
    }, {

      /*
       * Save data
       */
      name: "save",
      handler: function() {
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
      }
    }, {

      /*
       * Access data
       */
      name: "access",
      handler: function() {
        var error, key, result;
        key = arguments[0];
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
        return result || null;
      },
      value: null,
      validator: function(key) {
        return this.isString(key);
      }
    }, {
      name: "clear",
      handler: function() {},
      expose: false
    }
  ]
};


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

storage.modules.request = {
  handlers: [
    {

      /*
       * Asynchronous JavaScript and XML
       * 
       * @method  ajax
       * @param   options {Object/String}   请求参数列表/请求地址
       * @param   succeed {Function}        请求成功时的回调函数
       * @param   fail {Function}           请求失败时的回调函数
       * @return
       */
      name: "ajax",
      handler: function(options, succeed, fail) {
        return request(options, succeed, fail);
      }
    }, {

      /*
       * Synchronous JavaScript and XML
       * 
       * @method  sjax
       * @param   options {Object/String}   请求参数列表/请求地址
       * @param   succeed {Function}        请求成功时的回调函数
       * @param   fail {Function}           请求失败时的回调函数
       * @return
       */
      name: "sjax",
      handler: function(options, succeed, fail) {
        return request(options, succeed, fail, true);
      }
    }
  ]
};

storage.modules.HTML = {
  handlers: [
    {
      name: "encodeEntities",
      handler: function(string) {
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
      }
    }, {
      name: "decodeEntities",
      handler: function(string) {},
      expose: false
    }
  ]
};

resolvePathname = function(pathname) {
  if (pathname.charAt(0) === "\/") {
    return pathname;
  } else {
    return "\/" + pathname;
  }
};

storage.modules.URL = {
  handlers: [
    {

      /*
       * 获取 URL 的 pathname
       *
       * @method   pathname
       * @param    url {String}
       * @return   {String}
       */
      name: "pathname",
      handler: function(url) {
        return resolvePathname(this.isString(url) ? url : location.pathname);
      }
    }
  ]
};

_H.extend(storage.modules, _H);

window[LIB_CONFIG.name] = _H;
