"use strict"

__util = do ->

  "use strict"
  
  # Config of library
  LIB_CONFIG =
    name: "Ronin"
    version: "0.3.1"
  
  __proc = do ( window ) ->
    
    # Save a reference to some core methods.
    toString = {}.toString
  
    # default settings
    settings =
      validator: ->
        return true
  
    # storage for internal usage
    storage =
      # map of object types
      types: {}
  
    ###
    # Fill the map object-types, and add methods to detect object-type.
    # 
    # @private
    # @method   objectTypes
    # @return   {Object}
    ###
    objectTypes = ->
      types = "Boolean Number String Function Array Date RegExp Object".split " "
  
      for type in types
        do ( type ) ->
          # populate the storage.types map
          storage.types["[object #{type}]"] = lc = type.toLowerCase()
  
          if type is "Number"
            handler = ( target ) ->
              return if isNaN(target) then false else @type(target) is lc
          else
            handler = ( target ) ->
              return @type(target) is lc
  
          # add methods such as isNumber/isBoolean/...
          storage.methods["is#{type}"] = handler
  
      return storage.types
  
    ###
    # 判断某个对象是否有自己的指定属性
    #
    # !!! 不能用 object.hasOwnProperty(prop) 这种方式，低版本 IE 不支持。
    #
    # @private
    # @method   hasOwnProp
    # @param    obj {Object}    Target object
    # @param    prop {String}   Property to be tested
    # @return   {Boolean}
    ###
    hasOwnProp = ( obj, prop ) ->
      return if not obj? then false else Object::hasOwnProperty.call obj, prop
  
    ###
    # 为指定 object 或 function 定义属性
    #
    # @private
    # @method   defineProp
    # @param    target {Object}
    # @return   {Boolean}
    ###
    defineProp = ( target ) ->
      prop = "__#{LIB_CONFIG.name.toLowerCase()}__"
      value = true
  
      # throw an exception in IE9-
      try
        Object.defineProperty target, prop,
          __proto__: null
          value: value
      catch error
        target[prop] = value
  
      return true
  
    ###
    # 批量添加 method
    #
    # @private
    # @method  batch
    # @param   handlers {Object}   data of a method
    # @param   data {Object}       data of a module
    # @param   host {Object}       the host of methods to be added
    # @return
    ###
    batch = ( handlers, data, host ) ->
      methods = storage.methods
  
      if methods.isArray(data) or (methods.isPlainObject(data) and not methods.isArray(data.handlers))
        methods.each data, ( d ) ->
          batch d?.handlers, d, host
      else if methods.isPlainObject(data) and methods.isArray(data.handlers)
        methods.each handlers, ( info ) ->
          attach info, data, host
  
      return host
  
    ###
    # 构造 method
    #
    # @private
    # @method  attach
    # @param   set {Object}        data of a method
    # @param   data {Object}       data of a module
    # @param   host {Object}       the host of methods to be added
    # @return
    ###
    attach = ( set, data, host ) ->
      name = set.name
      methods = storage.methods
  
      if set.expose isnt false and not methods.isFunction host[name]
        handler = set.handler
        value = if hasOwnProp(set, "value") then set.value else data.value
        validators = [
            set.validator
            data.validator
            settings.validator
            ->
              return true
          ]
  
        break for validator in validators when methods.isFunction validator
  
        method = ->
          return if methods.isFunction(handler) and validator.apply(host, arguments) is true then handler.apply(host, arguments) else value;
        
        host[name] = method
  
      return host
  
    storage.methods =
      # ====================
      # Core methods
      # ====================
  
      ###
      # 扩展指定对象
      # 
      # @method  mixin
      # @param   unspecified {Mixed}
      # @return  {Object}
      ###
      mixin: ->
        args = arguments
        length = args.length
        target = args[0] or {}
        i = 1
        deep = false
  
        # Handle a deep copy situation
        if @type(target) is "boolean"
          deep = target
          target = args[1] or {}
          # skip the boolean and the target
          i = 2
  
        # Handle case when target is a string or something (possible in deep copy)
        target = {} if typeof target isnt "object" and not @isFunction target
  
        # 只传一个参数时，扩展自身
        if length is 1
          target = this
          i--
  
        while i < length
          opts = args[i]
  
          # Only deal with non-null/undefined values
          if opts?
            for name, copy of opts
              src = target[name]
  
              # 阻止无限循环
              if copy is target
                continue
  
              # Recurse if we're merging plain objects or arrays
              if deep and copy and (@isPlainObject(copy) or (copyIsArray = @isArray(copy)))
                if copyIsArray
                  copyIsArray = false
                  clone = if src and @isArray(src) then src else []
                else
                  clone = if src and @isPlainObject(src) then src else {}
  
                # Never move original objects, clone them
                target[name] = @mixin deep, clone, copy
              # Don't bring in undefined values
              else if copy isnt undefined
                target[name] = copy
  
          i++
  
        return target
  
      ###
      # 遍历
      # 
      # @method  each
      # @param   object {Object/Array/Array-Like/Function/String}
      # @param   callback {Function}
      # @return  {Mixed}
      ###
      each: ( object, callback ) ->
        if @isArray(object) or @isArrayLike(object) or @isString(object)
          index = 0
          while index < object.length
            ele = if @isString(object) then object.charAt(index) else object[index]
            break if callback.apply(ele, [ele, index++, object]) is false
        else if @isObject(object) or @isFunction(object)
          break for name, value of object when callback.apply(value, [value, name, object]) is false
  
        return object
  
      ###
      # 获取对象类型
      # 
      # @method  type
      # @param   object {Mixed}
      # @return  {String}
      ###
      type: ( object ) ->
        if arguments.length is 0
          result = null
        else
          result = if not object? then String(object) else storage.types[toString.call(object)] || "object"
          
        return result
  
      ###
      # 切割 Array-Like Object 片段
      #
      # @method   slice
      # @param    target {Array-Like}
      # @param    begin {Integer}
      # @param    end {Integer}
      # @return
      ###
      slice: ( target, begin, end ) ->
        if not target?
          result = []
        else
          end = Number end
          args = [(Number(begin) || 0)]
  
          args.push(end) if arguments.length > 2 and not isNaN(end)
  
          result = [].slice.apply target, args
          
        return  result
  
      ###
      # 判断某个对象是否有自己的指定属性
      #
      # @method   hasProp
      # @param    prop {String}   Property to be tested
      # @param    obj {Object}    Target object
      # @return   {Boolean}
      ###
      hasProp: ( prop, obj ) ->
        return hasOwnProp.apply this, [(if arguments.length < 2 then this else obj), prop]
  
      # ====================
      # Extension of detecting type of variables
      # ====================
  
      ###
      # 判断是否为 window 对象
      # 
      # @method  isWindow
      # @param   object {Mixed}
      # @return  {Boolean}
      ###
      isWindow: ( object ) ->
        return object and @isObject(object) and "setInterval" of object
  
      ###
      # 判断是否为 DOM 对象
      # 
      # @method  isElement
      # @param   object {Mixed}
      # @return  {Boolean}
      ###
      isElement: ( object ) ->
        return object and @isObject(object) and object.nodeType is 1
  
      ###
      # 判断是否为数字类型（字符串）
      # 
      # @method  isNumeric
      # @param   object {Mixed}
      # @return  {Boolean}
      ###
      isNumeric: ( object ) ->
        return not @isArray(object) and not isNaN(parseFloat(object)) and isFinite(object)
  
      ###
      # Determine whether a number is an integer.
      #
      # @method  isInteger
      # @param   object {Mixed}
      # @return  {Boolean}
      ###
      isInteger: ( object ) ->
        return @isNumeric(object) and /^-?[1-9]\d*$/.test(object)
  
      ###
      # 判断对象是否为纯粹的对象（由 {} 或 new Object 创建）
      # 
      # @method  isPlainObject
      # @param   object {Mixed}
      # @return  {Boolean}
      ###
      isPlainObject: ( object ) ->
        # This is a copy of jQuery 1.7.1.
        
        # Must be an Object.
        # Because of IE, we also have to check the presence of the constructor property.
        # Make sure that DOM nodes and window objects don't pass through, as well
        if not object or not @isObject(object) or object.nodeType or @isWindow(object)
          return false
  
        try
          # Not own constructor property must be Object
          if object.constructor and not @hasProp("constructor", object) and not @hasProp("isPrototypeOf", object.constructor.prototype)
            return false
        catch error
            # IE8,9 will throw exceptions on certain host objects
            return false
  
        key for key of object
  
        return key is undefined or @hasProp(key, object)
  
      ###
      # Determin whether a variable is considered to be empty.
      #
      # A variable is considered empty if its value is or like:
      #  - null
      #  - undefined
      #  - ""
      #  - []
      #  - {}
      #
      # @method  isEmpty
      # @param   object {Mixed}
      # @return  {Boolean}
      #
      # refer: http://www.php.net/manual/en/function.empty.php
      ###
      isEmpty: ( object ) ->
        result = false
  
        # null, undefined and ""
        if not object? or object is ""
          result = true
        # array and array-like object
        else if (@isArray(object) or @isArrayLike(object)) and object.length is 0
          result = true
        # plain object
        else if @isObject(object)
          result = true
  
          for name of object
            result = false
            break
  
        return result
  
      ###
      # 是否为类数组对象
      #
      # 类数组对象（Array-Like Object）是指具备以下特征的对象：
      # -
      # 1. 不是数组（Array）
      # 2. 有自动增长的 length 属性
      # 3. 以从 0 开始的数字做属性名
      #
      # @method  isArrayLike
      # @param   object {Mixed}
      # @return  {Boolean}
      ###
      isArrayLike: ( object ) ->
        result = false
  
        if @isObject(object) and not @isWindow object
          length = object.length
  
          result = true if object.nodeType is 1 and length or
            not @isArray(object) and
            not @isFunction(object) and
            (length is 0 or @isNumber(length) and length > 0 and (length - 1) of object)
  
        return result
  
    objectTypes()
  
    __proc = ( data, host ) ->
      return batch data?.handlers, data, host ? {}
  
    storage.methods.each storage.methods, ( handler, name )->
      # defineProp handler
      __proc[name] = handler
  
    return __proc
    
  # Save a reference to some core methods.
  toString = {}.toString
  
  # Regular expressions
  NAMESPACE_EXP = /^[0-9A-Z_.]+[^_.]?$/i
  
  # storage for internal usage
  storage =
    regexps:
      date:
        iso8601: /// ^
            (\d{4})\-(\d{2})\-(\d{2})                         # date
            (?:
              T(\d{2})\:(\d{2})\:(\d{2})(?:(?:\.)(\d{3}))?    # time
              (Z|[+-]\d{2}\:\d{2})?                           # timezone
            )?
          $ ///
      object:
        array: /\[(.*)\]/
        number: /(-?[0-9]+)/
    modules:
      Core: {}
  
  
  # ====================
  # Built-in methods from Miso
  # ====================
  
  storage.modules.Core.BuiltIn =
    # handlers: (name: name, handler: func for name, func of Miso when func.__miso__ is true)
    handlers: (name: name, handler: func for name, func of __proc)
  
  ###
  # Compare objects' values or references.
  # 
  # @private
  # @method  compareObjects
  # @param   base {Array/Object}
  # @param   target {Array/Object}
  # @param   strict {Boolean}
  # @param   connate {Boolean}
  # @return  {Boolean}
  ###
  compareObjects = ( base, target, strict, connate ) ->
    result = false
    plain = @isPlainObject base
  
    if (plain or connate) and strict
      result = target is base
    else
      if plain
        isRun = compareObjects.apply this, [@keys(base), @keys(target), false, true]
      else
        isRun = target.length is base.length
      
      if isRun
        @each base, ( n, i ) =>
          type = @type n
          t = target[i]
  
          # 有包装对象的原始类型
          if @inArray type, ["string", "number", "boolean"] > -1
            n_str = n + ""
            t_str = t + ""
            t_type = @type t
            illegalNums = ["NaN", "Infinity", "-Infinity"]
  
            if type is "number" and (@inArray(n_str, illegalNums) > -1 or @inArray(t_str, illegalNums) > -1)
              return result = false
            else
              return result = if strict is true then t is n else t_str is n_str
          # 无包装对象的原始类型
          else if @inArray(type, ["null", "undefined"]) > -1
            return result = t is n
          else if @inArray(type, ["date", "regexp", "function"]) > -1
            return result = if strict then t is n else t.toString() is n.toString()
          else if @inArray(type, ["array", "object"]) > -1
            return result = compareObjects.apply this, [n, t, strict, connate]
  
    return result
  
  ###
  # 将 Array、Object 转化为字符串
  # 
  # @private
  # @method  stringifyCollection
  # @param   collection {Array/Plain Object}
  # @return  {String}
  ###
  stringifyCollection = ( collection ) ->
    if @isArray collection
      stack = (@stringify ele for ele in collection)
    else
      stack = ("\"#{key}\":#{@stringify val}" for key, val of collection)
  
    return stack.join ","
  
  storage.modules.Core.Global =
    handlers: [
      {
        ###
        # 扩充对象
        # 
        # @method   extend
        # @param    data {Plain Object/Array}
        # @param    host {Object}
        # @return   {Object}
        ###
        name: "extend"
  
        handler: ( data, host ) ->
          return __proc data, host ? this
      },
      {
        ###
        # 别名
        # 
        # @method  alias
        # @param   name {String}
        # @return
        ###
        name: "alias"
        
        handler: ( name ) ->
          # 通过 _alias 判断是否已经设置过别名
          # 设置别名时要将原来的别名释放
          # 如果设置别名了，是否将原名所占的空间清除？（需要征求别人意见）
  
          if @isString name
            window[name] = this if window[name] is undefined
  
          return window[String(name)]
      },
      {
        ###
        # 更改 LIB_CONFIG.name
        # 
        # @method   mask
        # @param    guise {String}    New name for library
        # @return   {Boolean}
        ###
        name: "mask"
  
        handler: ( guise ) ->
          if @hasProp guise, window
            console.error "'#{guise}' has existed as a property of Window object." if window.console
          else
            lib_name = @__meta__.name
            window[guise] = window[lib_name]
  
            # IE9- 不能用 delete 关键字删除 window 的属性
            try
              result = delete window[lib_name]
            catch error
              window[lib_name] = undefined
              result = true
            
            @__meta__.name = guise
  
          return result
  
        validator: ( guise ) ->
          return @isString guise
  
        value: false
      },
      {
        ###
        # Returns the namespace specified and creates it if it doesn't exist.
        # Be careful when naming packages.
        # Reserved words may work in some browsers and not others.
        #
        # @method  namespace
        # @param   [hostObj] {Object}      Host object namespace will be added to
        # @param   [ns_str_1] {String}     The first namespace string
        # @param   [ns_str_2] {String}     The second namespace string
        # @param   [ns_str_*] {String}     Numerous namespace string
        # @param   [isGlobal] {Boolean}    Whether set window as the host object
        # @return  {Object}                A reference to the last namespace object created
        ###
        name: "namespace"
  
        handler: ->
          args = arguments
          ns = {}
          hostObj = args[0]
          
          # Determine the host object.
          (hostObj = if args[args.length - 1] is true then window else this) if not @isPlainObject hostObj
  
          @each args, ( arg ) =>
            if @isString(arg) and /^[0-9A-Z_.]+[^_.]?$/i.test(arg)
              obj = hostObj
  
              @each arg.split("."), ( part, idx, parts ) =>
                if not obj?
                  return false
  
                if not @hasProp part, obj
                  obj[part] = if idx is parts.length - 1 then null else {}
  
                obj = obj[part]
  
                return true
  
              ns = obj
  
            return true
  
          return ns
      },
      {
        ###
        # Compares two objects for equality.
        #
        # @method  equal
        # @param   base {Mixed}
        # @param   target {Mixed}
        # @param   strict {Boolean}    whether compares the two objects' references
        # @return  {Boolean}
        ###
        name: "equal"
  
        handler: ( base, target, strict ) ->
          result = false
          baseType = @type base
  
          if @type(target) is baseType
            plain_b = @isPlainObject base
  
            if plain_b and @isPlainObject(target) or baseType isnt "object"
              # 是否为“天然”的数组（以别于后来将字符串等转换成的数组）
              connate = @isArray base
  
              if not plain_b and not connate
                base = [base]
                target = [target]
  
              # If 'strict' is true, then compare the objects' references, else only compare their values.
              strict = false if not @isBoolean strict
  
              result = compareObjects.apply(this, [base, target, strict, connate])
  
          return result
  
        validator: ->
          return arguments.length > 1
  
        value: false
      },
      {
        ###
        # Returns a random integer between min and max, inclusive.
        # If you only pass one argument, it will return a number between 0 and that number.
        #
        # @method  random
        # @param   min {Number}
        # @param   max {Number}
        # @return  {Number}
        ###
        name: "random"
  
        handler: ( min, max ) ->
          if not max?
            max = min
            min = 0
  
          return min + Math.floor Math.random() * (max - min + 1)
      },
      {
        ###
        # 字符串化
        #
        # @method  stringify
        # @param   target {Variant}
        # @return  {String}
        ###
        name: "stringify"
  
        handler: ( target ) ->
          switch @type target
            when "object"
              result = if @isPlainObject(target) then "{#{stringifyCollection.call this, target}}" else result = ""
            when "array"
              result = "[#{stringifyCollection.call this, target}]"
            when "function", "date", "regexp"
              result = target.toString()
            when "string"
              result = "\"#{target}\""
            else
              try
                result = String target
              catch e
                result = ""
              
          return result
      }
      # ,
      # {
      #   name: "parse"
  
      #   handler: ( target ) ->
      #     target = @trim target
      #     result = target
  
      #     @each storage.regexps.object, ( r, o ) =>
      #       re_t = new RegExp "^#{r.source}$"
  
      #       if re_t.test target
      #         switch o
      #           when "array"
      #             re_g = new RegExp "#{r.source}", "g"
      #             re_c = /(\[.*\])/
      #             r = re_g.exec target
      #             result = []
  
      #             while r?
      #               @each r[1].split(","), ( unit, idx ) =>
      #                 result.push @parse unit
  
      #               break;
      #           when "number"
      #             result *= 1
  
      #         return false
      #       else
      #         return true
  
      #     return result
  
      #   validator: ( target ) ->
      #     return @isString target
  
      #   value: ""
      # }
    ]
  
      # /**
      #  * 恢复原名
      #  * 
      #  * @method  revert
      #  * @return
      #  */
      # // "revert": function() {},
  
      # /**
      #  * 新建对象子集
      #  * 
      #  * @method  create
      #  * @param   namespace {String}  Name of sub-collection
      #  * @param   object {Object}     Object added to the main object
      #  * @return
      #  */
      # /*create: function( namespace, object ) {
      #     this.namespace = object;
      # },*/
  
      # /**
      #  * 打印信息到控制台
      #  */
      # // "log": function() {}
  
  storage.modules.Core.Object =
    handlers: [
      {
        ###
        # Get a set of keys/indexes.
        # It will return a key or an index when pass the 'value' parameter.
        #
        # @method  keys
        # @param   object {Object/Function}    被操作的目标
        # @param   value {Mixed}               指定值
        # @return  {Array/String}
        #
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/keys
        ###
        name: "keys"
  
        handler: ( object, value ) ->
          keys = []
  
          @each object, ( v, k ) ->
            if v is value
              keys = k
  
              return false
            else
              keys.push k
  
          return if @isArray(keys) then keys.sort() else keys
  
        validator: ( object ) ->
          return object isnt null and not (object instanceof Array) and typeof object in ["object", "function"]
  
        value: []
      }
    ]
  
  # ====================
  # Array
  # ====================
  
  ###
  # Determine whether an object is an array.
  #
  # @private
  # @method  isCollection
  # @param   target {Array/Object}
  # @return  {Boolean}
  ###
  isArr = ( object ) ->
    return object instanceof Array
  
  ###
  # Determine whether an object is an array or a plain object.
  #
  # @private
  # @method  isCollection
  # @param   target {Array/Object}
  # @return  {Boolean}
  ###
  isCollection = ( target ) ->
    return @isArray(target) or @isPlainObject(target)
  
  ###
  # Return the maximum (or the minimum) element (or element-based computation).
  # Can't optimize arrays of integers longer than 65,535 elements.
  # See [WebKit Bug 80797](https://bugs.webkit.org/show_bug.cgi?id=80797)
  #
  # @private
  # @method  getMaxMin
  # @param   initialValue {Number}       Default return value of function
  # @param   funcName {String}           Method's name of Math object
  # @param   collection {Array/Object}   A collection to be manipulated
  # @param   callback {Function}         Callback for every element of the collection
  # @param   [context] {Mixed}           Context of the callback
  # @return  {Number}
  ###
  getMaxMin = ( initialValue, funcName, collection, callback, context ) ->
    result = value: initialValue, computed: initialValue
  
    if isCollection.call this, collection
      existCallback = @isFunction callback
  
      if not existCallback and @isArray(collection) and collection[0] is +collection[0] and collection.length < 65535
        return Math[funcName].apply Math, collection
  
      @each collection, ( val, idx, list ) ->
        computed = if existCallback then callback.apply(context, [val, idx, list]) else val
        result = value: val, computed: computed if funcName is "max" and computed > result.computed or funcName is "min" and computed < result.computed
  
    return result.value
  
  ###
  # A internal usage to flatten a nested array.
  #
  # @private
  # @method  flattenArray
  # @param   array {Array}
  # @return  {Mixed}
  ###
  flattenArray = ( array ) ->
    lib = this
    arr = []
  
    if lib.isArray array
      lib.each array, ( n, i ) ->
        arr = arr.concat flattenArray.call lib, n
    else
      arr = array
  
    return arr
  
  ###
  # 获取小数点后面的位数
  #
  # @private
  # @method  floatLength
  # @param   number {Number}
  # @return  {Integer}
  ###
  floatLength = ( number ) ->
    rfloat = /^([-+]?\d+)\.(\d+)$/
  
    return (if rfloat.test(number) then (number + "").match(rfloat)[2] else "").length
  
  ###
  # Create an array contains specified range.
  #
  # @private
  # @method  range
  # @param   from {Number/String}
  # @param   to {Number/String}
  # @param   step {Number}
  # @param   callback {Function}
  # @return  {Array}
  ###
  range = ( begin, end, step, callback ) ->
    array = []
  
    while begin <= end
      array.push if callback then callback(begin) else begin
      begin += step
  
    return array
  
  ###
  # Filter elements in a set.
  # 
  # @private
  # @method  filterElement
  # @param   target {Array/Object/String}    operated object
  # @param   callback {Function}             callback to change unit's value
  # @param   context {Mixed}                 context of callback
  # @param   method {Function}               Array's prototype method
  # @param   func {Function}                 callback for internal usage
  # @return  {Array/Object/String}           与被过滤的目标相同类型
  ###
  filterElement = ( target, callback, context, method, func ) ->
    result = null
    lib = this
  
    if lib.isFunction callback
      arrOrStr = lib.type(target) in ["array", "string"]
  
      # default context is the window object
      context = window if not context?
  
      # use Array's prototype method
      if lib.isFunction(method) && arrOrStr
        result = method.apply target, [callback, context]
      else
        plainObj = lib.isPlainObject target
  
        if plainObj
          result = {}
        else if arrOrStr
          result = []
  
        if result isnt null
          lib.each target, ( ele, idx ) ->
            cbVal = callback.apply context, [ele, idx, if lib.isString(target) then new String(target) else target]
            func result, cbVal, ele, idx, plainObj, arrOrStr
            return true
  
      result = result.join("") if lib.isString target
  
    return result
  
  storage.modules.Core.Array =
    value: []
  
    validator: ( object ) ->
      return isArr object
  
    handlers: [
      {
        ###
        # 元素在数组中的位置
        # 
        # @method  inArray
        # @param   element {Mixed}   待查找的数组元素
        # @param   array {Array}     数组
        # @param   from {Integer}    起始索引
        # @return  {Integer}
        ###
        name: "inArray"
  
        handler: ( element, array, from ) ->
          index = -1
          indexOf = Array::indexOf
          length = array.length
  
          from = if from then (if from < 0 then Math.max(0, length + from) else from) else 0
  
          if indexOf
            index = indexOf.apply array, [element, from]
          else
            while from < length
              if from of array and array[from] is element
                index = from
                break
  
              from++
  
          return index
  
        validator: ( element, array ) ->
          return isArr array
  
        value: -1
      },
      {
        ###
        # 过滤数组、对象
        #
        # @method  filter
        # @param   target {Array/Object/String}    被过滤的目标
        # @param   callback {Function}             过滤用的回调函数
        # @param   [context] {Mixed}               回调函数的上下文
        # @return  {Array/Object/String}           与被过滤的目标相同类型
        #
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/filter
        ###
        name: "filter"
  
        handler: ( target, callback, context ) ->
          return filterElement.apply this,
            [
              target
              callback
              context
              [].filter
              ( stack, cbVal, ele, idx, plainObj, arrOrStr ) ->
                if cbVal
                  if plainObj
                    stack[ idx ] = ele
                  else if arrOrStr
                    stack.push ele
            ]
  
        validator: ( target ) ->
          return isArr(target) or typeof target in ["object", "string"]
  
        value: null
      },
      {
        ###
        # 改变对象/数组/字符串每个单位的值
        #
        # @method  map
        # @param   target {Array/Object/String}    被操作的目标
        # @param   callback {Function}             改变单位值的回调函数
        # @param   [context] {Mixed}               回调函数的上下文
        # @return  {Array/Object/String}           与被过滤的目标相同类型
        #
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map
        ###
        name: "map"
  
        handler: ( target, callback, context ) ->
          return filterElement.apply this,
            [
              target
              callback
              context
              [].map
              ( stack, cbVal, ele, idx, plainObj, arrOrStr ) ->
                stack[idx] = cbVal
            ]
  
        validator: ( target ) ->
          return isArr(target) or typeof target in ["object", "string"]
  
        value: null
      },
      {
        ###
        # Calculate product of an array.
        #
        # @method  product
        # @param   array {Array}
        # @return  {Number}
        ###
        name: "product"
  
        handler: ( array ) ->
          result = 1
          count = 0
          lib = this
  
          lib.each array, ( number, index ) ->
            if lib.isNumeric number
              count++
              result *= number
  
          return if count is 0 then 0 else result
  
        value: null
      },
      {
        ###
        # Remove repeated values.
        # A numeric type string will be converted to number.
        #
        # @method  unique
        # @param   array {Array}
        # @param   last {Boolean}  whether keep the last value
        # @return  {Array}
        ###
        name: "unique"
  
        handler: ( array, last ) ->
          result = []
          lib = this
  
          last = !!last
  
          lib.each (if last then array.reverse() else array), ( n, i ) ->
            n = parseFloat(n) if lib.isNumeric n
            result.push(n) if lib.inArray(n, result) is -1
  
          if last
            array.reverse()
            result.reverse()
  
          return result
  
        value: null
      },
      {
        ###
        # 建立一个包含指定范围单元的数组
        # 返回数组中从 from 到 to 的单元，包括它们本身。
        # 如果 from > to，则序列将从 to 到 from。
        #
        # @method  range
        # @param   from {Number/String}    起始单元
        # @param   to {Number/String}      终止单元
        # @param   [step] {Number}         单元之间的步进值
        # @return  {Array}
        #
        # refer: http://www.php.net/manual/en/function.range.php
        ###
        name: "range"
  
        handler: ( from, to, step ) ->
          result = []
          lib = this
  
          # step 应该为正值。如果未指定，step 则默认为 1。
          step = if lib.isNumeric(step) and step * 1 > 0 then step * 1 else 1
  
          # Numeric
          if lib.isNumeric(from) and lib.isNumeric(to)
            l_from = floatLength from
            l_to = floatLength to
            l_step = floatLength step
            decDigit = Math.max l_from, l_to, l_step
  
            # 用整数处理浮点数，避免精度问题造成的 BUG
            if decDigit > 0
              decDigit = lib.zerofill(1, decDigit + 1) * 1
              step *= decDigit
  
              callback = ( number ) ->
                return number/decDigit
            else
              decDigit = 1
  
            from *= decDigit
            to *= decDigit
          # English alphabet
          else
            rCharL = /^[a-z]$/
            rCharU = /^[A-Z]$/
  
            from += ""
            to += ""
  
            if rCharL.test(from) and rCharL.test(to) or rCharU.test(from) and rCharU.test(to)
              from = from.charCodeAt(0)
              to = to.charCodeAt(0)
  
              callback = ( code ) ->
                return String.fromCharCode code
  
          if lib.isNumber(from) and lib.isNumber(to)
            if from > to
              result = range(to, from, step, callback).reverse()
            else if from < to
              result = range from, to, step, callback
            else
              result = [if callback then callback(from) else from]
  
          return result
  
        validator: ->
          return true
      },
      {
        ###
        # Apply a function simultaneously against two values of the 
        # array (default is from left-to-right) as to reduce it to a single value.
        #
        # @method  reduce
        # @param   array {Array}           An array of numeric values to be manipulated.
        # @param   callback {Function}     Function to execute on each value in the array.
        # @param   [initialValue] {Mixed}  Object to use as the first argument to the first call of the callback.
        # @param   [right] {Boolean}       Whether manipulates the array from right-to-left.
        # @return  {Mixed}
        #
        # Callback takes four arguments:
        #  - previousValue
        #          The value previously returned in the last invocation of the callback, or initialValue, if supplied.
        #  - currentValue
        #          The current element being processed in the array.
        #  - index
        #          The index of the current element being processed in the array.
        #  - array
        #          The array reduce was called upon.
        #
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/Reduce
        #        https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/ReduceRight
        ###
        name: "reduce"
  
        handler: ( array, callback, initialValue, right ) ->
          lib = this
  
          right = !!right
  
          if lib.isArray array
            args = arguments
            origin = if right then [].reduceRight else [].reduce
            hasInitVal = args.length > 2
  
            if origin
              result = origin.apply array, if hasInitVal then [callback, initialValue] else [callback]
            else
              index = 0
              length = array.length
  
              if not hasInitVal
                initialValue = array[0]
                index = 1
                length--
  
              if lib.isFunction callback
                length = if hasInitVal then length else length + 1
  
                while index < length
                  initialValue = callback.apply window, [initialValue, array[index], index, array]
                  index++
  
                result = initialValue
  
          return result
  
        value: null
      },
      {
        ###
        # Flattens a nested array.
        #
        # @method  flatten
        # @param   array {Array}   a nested array
        # @return  {Array}
        ###
        name: "flatten"
  
        handler: ( array ) ->
          return flattenArray.call this, array
      },
      {
        ###
        # Returns a shuffled copy of the list, using a version of the Fisher-Yates shuffle.
        #
        # @method  shuffle
        # @param   target {Mixed}
        # @return  {Array}
        #
        # refer: http://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
        ###
        name: "shuffle"
  
        handler: ( target ) ->
          lib = this
          shuffled = []
          index = 0
          rand = undefined
  
          lib.each target, ( value ) ->
            rand = lib.random index++
            shuffled[index - 1] = shuffled[rand]
            shuffled[rand] = value
            
            return true
  
          return shuffled
  
        value: null
      },
      {
        ###
        # Calculate the sum of values in a collection.
        #
        # @method  sum
        # @param   collection {Array/Object}
        # @return  {Number}
        ###
        name: "sum"
  
        handler: ( collection ) ->
          result = NaN
  
          if isCollection.call this, collection
            result = 0
  
            this.each collection, ( value ) ->
              result += (value * 1)
  
          return result
  
        validator: ->
          return true
  
        value: NaN
      },
      {
        ###
        # Return the maximum element or (element-based computation).
        #
        # @method  max
        # @param   target {Array/Object}
        # @param   callback {Function}
        # @param   [context] {Mixed}
        # @return  {Number}
        ###
        name: "max"
  
        handler: ( target, callback, context ) ->
          return getMaxMin.apply this, [-Infinity, "max", target, callback, (if arguments.length < 3 then window else context)]
  
        validator: ->
          return true
      },
      {
        ###
        # Return the minimum element (or element-based computation).
        #
        # @method  min
        # @param   target {Array/Object}
        # @param   callback {Function}
        # @param   [context] {Mixed}
        # @return  {Number}
        ###
        name: "min"
  
        handler: ( target, callback, context ) ->
          return getMaxMin.apply this, [Infinity, "min", target, callback, (if arguments.length < 3 then window else context)]
  
        validator: ->
          return true
      },
      {
        ###
        # 获取第一个单元
        #
        # @method   first
        # @param    target {String/Array/Array-like Object}
        # @return   {Anything}
        ###
        name: "first"
  
        handler: ( target ) ->
          return @slice(target, 0, 1)[0]
  
        validator: ->
          return true
      },
      {
        ###
        # 获取最后一个单元
        #
        # @method   last
        # @param    target {String/Array/Array-like Object}
        # @return   {Anything}
        ###
        name: "last"
  
        handler: ( target ) ->
          return @slice(target, -1)[0]
  
        validator: ->
          return true
      }
    ]
  
  # ====================
  # String
  # ====================
  
  ###
  # Ignore specified strings.
  #
  # @private
  # @method  ignoreSubStr
  # @param   string {String}         The input string. Must be one character or longer.
  # @param   length {Integer}        The number of characters to extract.
  # @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
  # @return  {String}
  ###
  ignoreSubStr = ( string, length, ignore ) ->
    lib = this;
    exp = if lib.isRegExp(ignore) then ignore else new RegExp(ignore, "ig")
  
    exp = new RegExp(exp.source, "ig") if not exp.global
  
    result = exp.exec string
  
    while result
      length += result[0].length if result.index < length
      result.lastIndex = 0
  
    return string.substring 0, length
  
  ###
  # 将字符串转换为以 \u 开头的十六进制 Unicode
  # 
  # @private
  # @method  unicode
  # @param   string {String}
  # @return  {String}
  ###    
  unicode = ( string ) ->
    lib = this
    result = []
    result = ("\\u#{lib.pad(Number(chr.charCodeAt(0)).toString(16), 4, '0').toUpperCase()}" for chr in string) if lib.isString string
  
    return result.join ""
  
  ###
  # 将 UTF8 字符串转换为 BASE64
  # 
  # @private
  # @method  utf8_to_base64
  # @param   string {String}
  # @return  {String}
  ###   
  utf8_to_base64 = ( string ) ->
    result = string
    btoa = window.btoa
    atob = window.atob
  
    if @.isString string
      result = btoa(unescape(encodeURIComponent(string))) if @isFunction btoa
  
    return result
  
  storage.modules.Core.String =
    value: ""
  
    validator: ( object ) ->
      return @isString object
  
    handlers: [
      {
        ###
        # 用指定占位符填补字符串
        # 
        # @method  pad
        # @param   string {String}         源字符串
        # @param   length {Integer}        生成字符串的长度，正数为在后面补充，负数则在前面补充
        # @param   placeholder {String}    占位符
        # @return  {String}
        ###
        name: "pad"
  
        handler: ( string, length, placeholder ) ->
          # 占位符只能指定为一个字符
          # 占位符默认为空格
          placeholder = "\x20" if @isString(placeholder) is false or placeholder.length isnt 1
  
          # Set length to 0 if it isn't an integer.
          length = 0 if not @isInteger length
  
          string = String string
  
          index = 1
          unit = String placeholder
          len = Math.abs(length) - string.length
  
          if len > 0
            # 补全占位符
            while index < len
              placeholder += unit
              index++
  
            string = if length > 0 then string + placeholder else placeholder + string
  
          return string
  
        validator: ( string ) ->
          return typeof string in ["string", "number"]
      },
      {
        ###
        # 将字符串首字母大写
        # 
        # @method  capitalize
        # @param   string {String}     源字符串
        # @param   isAll {Boolean}     是否将所有英文字符串首字母大写
        # @return  {String}
        ###
        name: "capitalize"
  
        handler: ( string, isAll ) ->
          exp = "[a-z]+"
  
          return string.replace (if isAll is true then new RegExp(exp, "ig") else new RegExp(exp)), ( c ) ->
              return c.charAt(0).toUpperCase() + c.slice(1).toLowerCase()
      },
      {
        ###
        # 将字符串转换为驼峰式
        # 
        # @method  camelCase
        # @param   string {String}         源字符串
        # @param   is_upper {Boolean}      是否为大驼峰式
        # @return  {String}
        ###
        name: "camelCase"
  
        handler: ( string, is_upper ) ->
          string = string.toLowerCase().replace /[-_\x20]([a-z]|[0-9])/ig, ( all, letter ) ->
              return letter.toUpperCase()
  
          firstLetter = string.charAt(0)
  
          string = (if is_upper is true then firstLetter.toUpperCase() else firstLetter.toLowerCase()) + string.slice(1)
  
          return string
      },
      {
        ###
        # 补零
        # 
        # @method  zerofill
        # @param   number {Number}     源数字
        # @param   digit {Integer}     数字位数，正数为在后面补充，负数则在前面补充
        # @return  {String}
        ###
        name: "zerofill"
  
        handler: ( number, digit ) ->
          result = ""
          lib = this
          rfloat = /^([-+]?\d+)\.(\d+)$/
          isFloat = rfloat.test number
          prefix = ""
  
          digit = parseInt digit
  
          # 浮点型数字时 digit 则为小数点后的位数
          if digit > 0 and isFloat
            number = (number + "").match rfloat
            prefix = "#{number[1] * 1}."
            number = number[2]
          # Negative number
          else if number * 1 < 0
            prefix = "-"
            number = (number + "").substring(1)
  
          result = lib.pad number, digit, "0"
          result = if digit < 0 and isFloat then "" else  prefix + result
  
          return result
  
        validator: ( number, digit ) ->
          return @isNumeric(number) and @isNumeric(digit) and /^-?[1-9]\d*$/.test(digit)
      },
      {
        ###
        # Removes whitespace from both ends of the string.
        #
        # @method  trim
        # @param   string {String}
        # @return  {String}
        # 
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/Trim
        ###
        name: "trim"
  
        handler: ( string ) ->
          # Make sure we trim BOM and NBSP (here's looking at you, Safari 5.0 and IE)
          rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g
          func = "".trim
  
          return if func and not func.call("\uFEFF\xA0") then func.call(string) else string.replace(rtrim, "")
      }
      # ,
      # {
      #   ###
      #   # Returns the characters in a string beginning at the specified location through the specified number of characters.
      #   #
      #   # @method  substr
      #   # @param   string {String}         The input string. Must be one character or longer.
      #   # @param   start {Integer}         Location at which to begin extracting characters.
      #   # @param   length {Integer}        The number of characters to extract.
      #   # @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
      #   # @return  {String}
      #   # 
      #   # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/substr
      #   ###
      #   name: "substr"
  
      #   handler: ( string, start, length, ignore ) ->
      #     args = arguments
      #     lib = this
  
      #     if args.length is 3 and lib.isNumeric(start) and start > 0 and (lib.isString(length) or lib.isRegExp(length))
      #       string = ignoreSubStr.apply lib, [string, start, length]
      #     else if lib.isNumeric(start) and start >= 0
      #       length = string.length if not lib.isNumeric(length) or length <= 0
      #       string = if lib.isString(ignore) or lib.isRegExp(ignore) then ignoreSubStr.apply(lib, [string.substring(start), length, ignore]) else string.substring(start, length)
  
      #     return string
      # }
      # ,
      # {
      #   ###
      #   # Return information about characters used in a string.
      #   #
      #   # Depending on mode will return one of the following:
      #   #  - 0: an array with the byte-value as key and the frequency of every byte as value
      #   #  - 1: same as 0 but only byte-values with a frequency greater than zero are listed
      #   #  - 2: same as 0 but only byte-values with a frequency equal to zero are listed
      #   #  - 3: a string containing all unique characters is returned
      #   #  - 4: a string containing all not used characters is returned
      #   # 
      #   # @method  countChars
      #   # @param   string {String}
      #   # @param   [mode] {Integer}
      #   # @return  {JSON}
      #   #
      #   # refer: http://www.php.net/manual/en/function.count-chars.php
      #   ###
      #   name: "countChars"
  
      #   handler: ( string, mode ) ->
      #     result = null;
      #     lib = this
  
      #     mode = 0 if not lib.isInteger(mode) or mode < 0
  
      #     bytes = {}
      #     chars = []
  
      #     lib.each string, ( chr, idx ) ->
      #       code = chr.charCodeAt(0)
  
      #       if lib.isNumber bytes[code]
      #         bytes[code]++
      #       else
      #         bytes[code] = 1
      #         chars.push(chr) if lib.inArray(chr, chars) < 0
  
      #     switch mode
      #       when 0
      #         break
      #       when 1
      #         result = bytes
      #       when 2
      #         break
      #       when 3
      #         result = chars.join ""
      #       when 4
      #         break
  
      #     return result
  
      #   value: null
      # }
    ]
      # /**
      #  * 将字符串转换为以 \u 开头的十六进制 Unicode
      #  * 
      #  * @method  unicode
      #  * @param   string {String}
      #  * @return  {String}
      #  */
      # // {
      # //     name: "unicode",
      # //     handler: function( string ) {
      # //         return unicode.call(this, string);
      # //     }
      # // }
  
      # /**
      #  * 对字符串编码
      #  * 
      #  * @method  encode
      #  * @param   target {String}     目标
      #  * @param   type {String}       编码类型
      #  * @return  {String}
      #  */
      # // {
      # //     name: "encode",
      # //     handler: function( target, type ) {
      # //         var result = target;
  
      # //         type = String(type).toLowerCase();
  
      # //         switch( type ) {
      # //             case "unicode":
      # //                 result = unicode.call(this, target);
      # //                 break;
      # //             case "base64":
      # //                 result = utf8_to_base64.call(this, target);
      # //                 break;
      # //         }
  
      # //         return result;
      # //     }
      # // },
  
      # /**
      #  * 对字符串解码
      #  * 
      #  * @method  decode
      #  * @param   target {String}     目标
      #  * @param   type {String}       目标类型
      #  * @return  {String}
      #  */
      # // {
      # //     name: "decode",
      # //     handler: function( target, type ) {}
      # // }
  
  # ====================
  # Date and time
  # ====================
  
  ###
  # 将日期字符串转化为日期对象
  #
  # @private
  # @method   dateStr2obj
  # @param    date_str {String}
  # @return   {Date}
  ###
  dateStr2obj = ( date_str ) ->
    date_str = @trim date_str
    date = new Date date_str
  
    if isNaN date.getTime()
      # 为了兼容 IE9-
      date_parts = date_str.match storage.regexps.date.iso8601
      date = if date_parts? then ISOstr2date.call(this, date_parts) else new Date
  
    return date
  
  ###
  # ISO 8601 日期字符串转化为日期对象
  #
  # @private
  # @method   ISOstr2date
  # @param    date_parts {Array}
  # @return   {Date}
  ###
  ISOstr2date = ( date_parts ) ->
    date_parts.shift()
  
    date = UTCstr2date.call this, date_parts
    tz_offset = timezoneOffset date_parts.slice(-1)[0]
  
    date.setTime(date.getTime() - tz_offset) unless tz_offset is 0
  
    return date
  
  ###
  # 转化为 UTC 日期对象
  #
  # @private
  # @method   UTCstr2date
  # @param    date_parts {Array}
  # @return   {Date}
  ###
  UTCstr2date = ( date_parts ) ->
    handlers = [
        "FullYear"
        "Month"
        "Date"
        "Hours"
        "Minutes"
        "Seconds"
        "Milliseconds"
      ]
    date = new Date
  
    @each date_parts, ( ele, i ) ->
      if ele? and ele isnt ""
        handler = handlers[i]
  
        date["setUTC#{handler}"](ele * 1 + if handler is "Month" then -1 else 0) if handler?
  
    return date
  
  ###
  # 相对于 UTC 的偏移值
  #
  # @private
  # @method   timezoneOffset
  # @param    timezone {String}
  # @return   {Integer}
  ###
  timezoneOffset = ( timezone ) ->
    offset = 0
  
    if /^(Z|[+-]\d{2}\:\d{2})$/.test timezone
      cap = timezone.charAt(0)
  
      if cap isnt "Z"
        offset = timezone.substring(1).split(":")
        offset = (cap + (offset[0] * 60 + offset[1] * 1)) * 60 * 1000
  
    return offset
  
  DateTimeNames = 
    month:
      long: [
          "January", "February", "March", "April",
          "May", "June", "July", "August",
          "September", "October", "November", "December"
        ]
      short: [
          "Jan", "Feb", "Mar", "Apr",
          "May", "Jun", "Jul", "Aug",
          "Sep", "Oct", "Nov", "Dec"
        ]
    week:
      long: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thurday", "Friday", "Saturday"]
      short: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  
  DateTimeFormats = 
    "d": ( date ) ->
      return dtwz.call this, date.getDate()
    "D": ( date ) ->
      return DateTimeNames.week.short[date.getDay()]
    "j": ( date ) ->
      return date.getDate()
    "l": ( date ) ->
      return DateTimeNames.week.long[date.getDay()]
    "N": ( date ) ->
      day = date.getDay()
      day = 7 if day is 0
      return day
    "S": ( date ) ->
      switch String(date.getDate()).slice -1
        when "1" then suffix = "st"
        when "2" then suffix = "nd"
        when "3" then suffix = "rd"
        else suffix = "th"
      return suffix
    "w": ( date ) ->
      return date.getDay()
    # "z": ( date ) ->
    # "W": ( date ) ->
    "F": ( date ) ->
      return DateTimeNames.month.long[date.getMonth()]
    "m": ( date ) ->
      return dtwz.call this, DateTimeFormats.n.call(this, date)
    "M": ( date ) ->
      return DateTimeNames.month.short[date.getMonth()]
    "n": ( date ) ->
      return date.getMonth() + 1
    # "t": ( date ) ->
    # "L": ( date ) ->
    # "o": ( date ) ->
    "Y": ( date ) ->
      return date.getFullYear()
    "y": ( date ) ->
      return String(date.getFullYear()).slice -2
    "a": ( date ) ->
      h = date.getHours()
      return if 0 < h < 12 then "am" else "pm"
    "A": ( date ) ->
      return DateTimeFormats.a.call(this, date).toUpperCase()
    # "B": ( date ) ->
    "g": ( date ) ->
      h = date.getHours()
      h = 24 if h is 0
      return if h > 12 then h - 12 else h
    "G": ( date ) ->
      return date.getHours()
    "h": ( date ) ->
      return dtwz.call this, DateTimeFormats.g.call(this, date)
    "H": ( date ) ->
      return dtwz.call this, DateTimeFormats.G.call(this, date)
    "i": ( date ) ->
      return dtwz.call this, date.getMinutes()
    "s": ( date ) ->
      return dtwz.call this, date.getSeconds()
    # "u": ( date ) ->
  
  ###
  # 添加前导“0”
  #
  # @private
  # @method   dtwz
  # @param    datetime {Integer}
  # @return   {String}
  ###
  dtwz = ( datetime ) ->
    return @pad datetime, -2, "0"
  
  ###
  # 格式化日期
  #
  # @private
  # @method   formatDate
  # @param    format {String}
  # @param    date {Date}
  # @return   {String}
  ###
  formatDate = ( format, date ) ->
    date = new Date if not @isDate(date) or isNaN(date.getTime())
    context = this
    formatted = format.replace new RegExp("([a-z]|\\\\)", "gi"), ( m, p..., o, s ) ->
      if m is "\\"
        return ""
      else
        handler = DateTimeFormats[m] if s.charAt(o - 1) isnt "\\"
      return if handler? then handler.call(context, date) else m
  
    return formatted
  
  storage.modules.Core.Date =
    handlers: [
      {
        ###
        # 格式化日期对象/字符串
        #
        # format 参照 PHP：
        #   http://www.php.net/manual/en/function.date.php
        # 
        # @method  date
        # @param   format {String}
        # @param   [date] {Date/String}
        # @return  {String}
        ###
        name: "date"
  
        handler: ( format, date ) ->
          if @isString date
            date = dateStr2obj.call this, date
  
          return formatDate.apply this, [format, date]
  
        value: ""
  
        validator: ( format ) ->
          return @isString format
      },
      {
        ###
        # 取得当前时间
        #
        # @method   now
        # @param    [is_object] {Boolean}
        # @return   {Integer/Date}
        ###
        name: "now"
  
        handler: ( is_object ) ->
          date = new Date
  
          return if is_object is true then date else date.getTime()
      }
    ]
  
  __util = __proc storage.modules
  
  # Set the library' info as a meta data
  try
    Object.defineProperty __util, "__meta__",
      __proto__: null
      writable: true
      value: LIB_CONFIG
  catch error
    __util.mixin
      __meta__: LIB_CONFIG
  
  window[LIB_CONFIG.name] = __util
  
  return __util

Storage = do ( __util ) ->
  hasProp = __util.hasProp
  isPlainObj = __util.isPlainObject

  storage = {}

  isNamespaceStr = ( str ) ->
    return /^[0-9a-z_.]+[^_.]?$/i.test str

  # Convert a namespace string to a plain object
  str2obj = ( str ) ->
    obj = storage

    __util.each str.split("."), ( part ) ->
      obj[part] = {} if not hasProp part, obj
      obj = obj[part]

    return obj

  getData = ( host, key, map ) ->
    __util.each key.split("."), ( part ) ->
      r = hasProp part, host
      host = host[part]

      return r

    s = @settings
    map = {} if not isPlainObj map
    keys = if isPlainObj(s.keys) then s.keys else {}
    regexp = s.formatRegExp
    result = s.value(host)

    if __util.isRegExp regexp
      result = result.replace regexp, ( m, k ) =>
        # 以传入的值为优先
        if hasProp k, map
          r = map[k]
        # 预先设置的值
        else if hasProp k, keys
          r = keys[k]
        else
          r = m

        return if __util.isFunction(r) then r() else r

    return result

  class Storage
    constructor: ( namespace ) ->
      @settings =
        formatRegExp: null
        allowKeys: false
        keys: {}
        value: ( v ) ->
          return v ? ""

      @storage = if isNamespaceStr(namespace) then str2obj("#{namespace}") else storage

    set: ( data ) ->
      __util.mixin true, @storage, data

    get: ( key, map ) ->
      if __util.isString key
        data = getData.apply this, [@storage, key, map]
      else if @settings.allowKeys is true
        data = __util.keys @storage

      return data ? null

    config: ( settings ) ->
      __util.mixin @settings, settings

  return Storage

Environment = do ( __util ) ->
  nav = navigator
  ua = nav.userAgent.toLowerCase()

  suffix =
    windows:
      "5.1": "XP"
      "5.2": "XP x64 Edition"
      "6.0": "Vista"
      "6.1": "7"
      "6.2": "8"
      "6.3": "8.1"

  platformName = ->
    name = /^[\w.\/]+ \(([^;]+?)[;)]/.exec(ua)[1].split(" ").shift()
    return if name is "compatible" then "windows" else name

  platformVersion = ->
    return (/windows nt ([\w.]+)/.exec(ua) or
            /os ([\w]+) like mac/.exec(ua) or
            /mac os(?: [a-z]*)? ([\w.]+)/.exec(ua) or
            [])[1]?.replace /_/g, "."

  detectPlatform = ->
    platform =
      touchable: false
      version: platformVersion()
    
    platform[platformName()] = true

    if platform.windows
      platform.version = suffix.windows[platform.version]
      platform.touchable = /trident[ \/][\w.]+; touch/.test ua
    else if platform.ipod or platform.iphone or platform.ipad
      platform.touchable = platform.ios = true

    return platform

  # jQuery 1.9.x 以下版本中 jQuery.browser 的实现方式
  # IE 只能检测 IE11 以下
  jQueryBrowser = ->
    browser = {}
    match = /(chrome)[ \/]([\w.]+)/.exec(ua) or
            /(webkit)[ \/]([\w.]+)/.exec(ua) or
            /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua) or
            /(msie) ([\w.]+)/.exec(ua) or
            ua.indexOf("compatible") < 0 and /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(ua) or
            []
    result =
      browser: match[1] or ""
      version: match[2] or "0"

    if result.browser
      browser[result.browser] = true
      browser.version = result.version

    if browser.chrome
      browser.webkit = true
    else if browser.webkit
      browser.safari = true

    return browser

  detectBrowser = ->
    # IE11 及以上
    match = /trident.*? rv:([\w.]+)/.exec(ua)

    if match
      browser =
        msie: true
        version: match[1]
    else
      browser = jQueryBrowser()

      if browser.mozilla
        browser.firefox = true
        match = /firefox[ \/]([\w.]+)/.exec(ua)
        browser.version = match[1] if match

    browser.language = navigator.language or navigator.browserLanguage

    return browser

  # Create an ActiveXObject (IE specified)
  createAXO = ( type ) ->
    try
      axo = new ActiveXObject type
    catch e
      axo = null

    return axo

  hasReaderActiveX = ->
    if __util.hasProp "ActiveXObject", window
      axo = createAXO "AcroPDF.PDF"
      axo = createAXO "PDF.PdfCtrl" if not axo

    return axo?

  hasReader = ->
    result = false

    __util.each nav.plugins, ( plugin ) ->
      result = /Adobe Reader|Adobe PDF|Acrobat/gi.test plugin.name
      return not result

    return result

  hasGeneric = ->
    return nav.mimeTypes["application/pdf"]?.enabledPlugin?

  PDFReader = ->
    return hasReader() or hasReaderActiveX() or hasGeneric()
     
  class Environment
    constructor: ->
      @platform = detectPlatform()
      @browser = detectBrowser()
      @plugins =
        # refer: https://github.com/pipwerks/PDFObject/blob/master/pdfobject.js
        pdf: PDFReader()

  return Environment

__proj = do ( window, __util ) ->
  
  # Node-types
  ELEMENT_NODE = 1
  ATTRIBUTE_NODE = 2
  TEXT_NODE = 3
  CDATA_SECTION_NODE = 4
  ENTITY_REFERENCE_NODE = 5
  ENTITY_NODE = 6
  PROCESSING_INSTRUCTION_NODE = 7
  COMMENT_NODE = 8
  DOCUMENT_NODE = 9
  DOCUMENT_TYPE_NODE = 10
  DOCUMENT_FRAGMENT_NODE = 11
  NOTATION_NODE = 12

  # Regular expressions
  REG_NAMESPACE = /^[0-9A-Z_.]+[^_.]?$/i

  # Main objects
  $ = jQuery
  _ENV =
    lang: document.documentElement.lang || document.documentElement.getAttribute("lang") || navigator.language || navigator.browserLanguage
  __proj = __util

  # JavaScript APIs' support
  support =
    storage: !!window.localStorage

  # 限制器
  limiter =
    ###
    # 键
    #
    # @property  key
    # @type      {Object}
    ###
    key:
      # 限制访问的 storage key 列表
      storage: ["sandboxStarted", "config", "fn", "buffer", "pool"]

  # 内部数据载体
  storage =
    ###
    # 沙盒运行状态
    #
    # @property  sandboxStarted
    # @type      {Boolean}
    ###
    sandboxStarted: false

    ###
    # 配置
    #
    # @property  config
    # @type      {Object}
    ###
    config:
      debug: true
      platform: ""
      locale: _ENV.lang
      lang: _ENV.lang.split("-")[0]

    ###
    # 函数
    #
    # @property  fn
    # @type      {Object}
    ###
    fn:
      # DOM tree 构建未完成（sandbox 启动）时调用的处理函数
      prepare: []
      # DOM tree 构建已完成时调用的处理函数
      ready: []
      # 初始化函数
      init:
        # Ajax 请求
        ajaxHandler: ( succeed, fail ) ->
          return {
            # 状态码为 200
            success: ( data, textStatus, jqXHR ) ->
              args = __proj.slice arguments
              ###
              # 服务端在返回请求结果时必须是个 JSON，如下：
              #    {
              #      "code": {Integer}       # 处理结果代码，code > 0 为成功，否则为失败
              #      "message": {String}     # 请求失败时的提示信息
              #    }
              ###
              if data.code > 0
                succeed.apply($, args) if __proj.isFunction succeed
              else
                if __proj.isFunction fail
                  fail.apply $, args
            # 状态码为非 200
            error: $.noop
          }
      handler: {}

    modules:
      utils: {}
      flow: {}
      project: {}
      storage: {}
      request: {}
      HTML: {}
      URL: {}

    ###
    # 缓冲区，存储临时数据
    #
    # @property  buffer
    # @type      {Object}
    ###
    buffer: {}

    ###
    # 对象池
    # 
    # @property  pool
    # @type      {Object}
    ###
    pool: {}

  ###
  # 取得数组或类数组对象中最后一个元素
  #
  # @private
  # @method  last
  # @return
  ###
  last = ( array ) ->
    return __proj.slice(array, -1)[0]

  ###
  # 全局配置
  # 
  # @private
  # @method    setup
  ###
  setup = ->
    # Ajax 全局配置
    $.ajaxSetup type: "post", dataType: "json"
    
    # Ajax 出错
    $(document).ajaxError ( event, jqXHR, ajaxSettings, thrownError ) ->
      response = jqXHR.responseText
      
      # if response isnt undefined
        # To do sth.
      
      return false
    
    # $( document ).bind({
    #   "keypress": function( e ) {
    #     var pointer = this;
        
    #     // 敲击回车键
    #     if ( e.keyCode == 13 ) {
    #       var CB_Enter = bindHandler( "CB_Enter" );
    #       var dialogs = $(":ui-dialog:visible");
          
    #       // 有被打开的对话框
    #       if ( dialogs.size() ) {
    #         // 按 z-index 值从大到小排列对话框数组
    #         [].sort.call(dialogs, function( a, b ) {
    #           return $(b).closest(".ui-dialog").css("z-index") * 1 - $(a).closest(".ui-dialog").css("z-index") * 1;
    #         });
    #         // 触发对话框的确定/是按钮点击事件
    #         $("[data-button-flag='ok'], [data-button-flag='yes']", $([].shift.call(dialogs)).closest(".ui-dialog")).each(function() {
    #           $(this).trigger("click");
    #           return false;
    #         });
    #       }
    #       else if ( __proj.isFunction(CB_Enter) ) {
    #         CB_Enter.call(pointer);
    #       }
    #     }
    #   }
    # });

  ###
  # 将处理函数绑定到内部命名空间
  # 
  # @private
  # @method  bindHandler
  # @return
  ###
  bindHandler = ->
    args = arguments
    name = args[0]
    handler = args[1]
    fnList = storage.fn.handler
    
    # 无参数时返回函数列表
    if args.length is 0
      handler = clone fnList
    # 传入函数名
    else if __proj.isString name
      # 保存
      if __proj.isFunction handler
        fnList[name] = handler
      # 获取
      else
        handler = fnList[name]
    # 传入函数列表
    else if __proj.isPlainObject name
      handler = {}

      __proj.each name, ( func, funcName ) ->
        handler[funcName] = fnList[funcName] = func if __proj.isFunction func
      
    return handler

  ###
  # 将处理函数从内部命名空间删除
  # 
  # @private
  # @method  removeHandler
  # @return
  ###
  removeHandler = ( name ) ->
    fnList = storage.fn.handler

    # 函数名
    if __proj.isString name
      if __proj.hasProp name, fnList
        try
          result = delete fnList[name]
        catch e
          fnList[name] = undefined
          result = true
      else
        result = false
    # 函数名列表
    else
      __proj.each name, ( n, i ) ->
        result = removeHandler n

    return result        

  ###
  # 执行指定函数
  # 
  # @private
  # @method  runHandler
  # @param   name {String}         函数名
  # @param   [args, ...] {List}    函数的参数
  # @return  {Variant}
  ###
  runHandler = ( name ) ->
    result = undefined
    
    # 指定函数列表（数组）时
    if __proj.isArray name
      func.call window for func in name when __proj.isFunction(func) || __proj.isFunction(func = storage.fn.handler[func])
    # 指定函数名时，从函数池里提取对应函数
    else if __proj.isString name
      func = storage.fn.handler[name]
      result = func.apply window, __proj.slice(arguments, 1) if __proj.isFunction func
    
    return result

  ###
  # 将函数加到指定队列中
  # 
  # @private
  # @method  pushHandler
  # @param   handler {Function}    函数
  # @param   queue {String}        队列名
  ###
  pushHandler = ( handler, queue ) ->
    storage.fn[queue].push handler if __proj.isFunction handler

  ###
  # 克隆对象并返回副本
  # 
  # @private
  # @method  clone
  # @param   source {Object}       源对象，只能为数组或者纯对象
  # @return  {Object}
  ###
  clone = ( source ) ->
    result = null
    
    if __proj.isArray(source) or source.length isnt undefined
      result = [].concat [], __proj.slice source
    else if __proj.isPlainObject source
      result = $.extend true, {}, source
    
    return result

  ###
  # 获取初始化函数
  # 
  # @private
  # @method  initializer
  # @return  {Function}
  ###
  initializer = ( key ) ->
    return storage.fn.init[key]

  ###
  # Get data from internal storage
  #
  # @private
  # @method  getStorageData
  # @param   ns_str {String}   Namespace string
  # @param   ignore {Boolean}  忽略对 storage key 的限制
  # @return  {String}
  ###
  getStorageData = ( ns_str, ignore ) ->
    parts = ns_str.split "."
    result = null

    if ignore || !isLimited parts[0], limiter.key.storage
      result = storage

      __proj.each parts, ( part ) ->
        rv = __proj.hasProp(part, result)
        result = result[part]
        return rv

    return result

  ###
  # Set data into internal storage
  #
  # @private
  # @method  setStorageData
  # @param   ns_str {String}   Namespace string
  # @param   data {Variant}    
  # @return  {Variant}
  ###
  setStorageData = ( ns_str, data ) ->
    parts = ns_str.split "."
    length = parts.length
    isObj = __proj.isPlainObject data

    if length is 1
      key = parts[0]
      result = setData storage, key, data, __proj.hasProp(key, storage)
    else
      result = storage

      __proj.each parts, ( n, i ) ->
        if i < length - 1
          result[n] = {} if not __proj.hasProp(n, result)
        else
          result[n] = setData result, n, data, __proj.isPlainObject result[n]
        result = result[n]
        return true

    return result

  setData = ( target, key, data, condition ) ->
    if condition && __proj.isPlainObject data
      $.extend true, target[key], data
    else
      target[key] = data

    return target[key]

  ###
  # Determines whether a propery belongs an object
  #
  # @private
  # @method  isExisted
  # @param   host {Object}   A collection of properties
  # @param   prop {String}   The property to be determined
  # @param   type {String}   Limits property's variable type
  # @return  {Boolean}
  ###
  isExisted = ( host, prop, type ) ->
    return __proj.isObject(host) and __proj.isString(prop) and __proj.hasProp(prop, host) and __proj.type(host[prop]) is type

  ###
  # Determines whether a key in a limited key list
  #
  # @private
  # @method  isLimited
  # @param   key {String}   Key to be determined
  # @param   list {Array}   Limited key list
  # @return  {Boolean}
  ###
  isLimited = ( key, list ) ->
    return $.inArray(key, list) > -1

  ###
  # 添加到内部存储对象的访问 key 限制列表中
  #
  # @private
  # @method  limit
  # @param   key {String}  Key to be limited
  # @return
  ###
  limit = ( key ) ->
    limiter.key.storage.push key

  ###
  # 将内部 class 曝露到外部
  #
  # @private
  # @method  exposeClasses
  # @return
  ###
  exposeClasses = ->
    classes = {Storage}

    try
      Object.defineProperty __proj, "__class__",
        __proto__: null
        value: classes
    catch error
      __proj.mixin __class__: classes

  storage.modules.handler =
    handlers: [
      {
        ###
        # 将外部处理函数引入到沙盒中
        # 
        # @method  queue
        # @return
        ###
        name: "queue"

        handler: ->
          return bindHandler.apply window, @slice arguments
      },
      {
        ###
        # 将指定处理函数从沙盒中删除
        # 
        # @method  dequeue
        # @return
        ###
        name: "dequeue"

        handler: removeHandler

        validator: ( name ) ->
          return @isString(name) or @isArray(name)

        value: false
      },
      {
        ###
        # 执行指定函数
        # 
        # @method  run
        # @return  {Variant}
        ###
        name: "run"

        handler: ->
          return runHandler.apply window, @slice arguments
      },
      {
        ###
        # Determines whether a function has been defined
        #
        # @method  functionExists
        # @param   funcName {String}
        # @param   isWindow {Boolean}
        # @return  {Boolean}
        ###
        name: "functionExists"

        handler: ( funcName, isWindow ) ->
          return isExisted (if isWindow is true then window else storage.fn.handler), funcName, "function"
      }
    ]

  storage.fn.init.runSandbox = ( prepareHandlers, readyHandlers ) ->
    # 全局配置
    # setup();
    # DOM tree 构建前的函数队列
    runHandler prepareHandlers
    
    # DOM tree 构建后的函数队列
    $(document).ready ->
      runHandler readyHandlers

  ###
  # 重新配置系统参数
  # 
  # @private
  # @method  resetConfig
  # @param   setting {Object}      配置参数
  # @return  {Object}              （修改后的）系统配置信息
  ###
  resetConfig = ( setting ) ->
    return clone if __proj.isPlainObject(setting) then $.extend(storage.config, setting) else storage.config

  storage.modules.execution =
    handlers: [
      {
        ###
        # 沙盒
        #
        # 封闭运行环境的开关，每个页面只能运行一次
        # 
        # @method  sandbox
        # @param   setting {Object}      系统环境配置
        # @return  {Object/Boolean}      （修改后的）系统环境配置
        ###
        name: "sandbox"

        handler: ( setting ) ->
          # 返回值为修改后的系统环境配置
          result = resetConfig setting

          initializer("runSandbox").apply this, [storage.fn.prepare, storage.fn.ready]
          
          storage.sandboxStarted = true
          
          return result || false

        value: false

        validator: ->
          return storage.sandboxStarted isnt true
      },
      {
        ###
        # DOM 未加载完时调用的处理函数
        # 主要进行事件委派等与 DOM 加载进程无关的操作
        #
        # @method  prepare
        # @param   handler {Function}
        # @return
        ###
        name: "prepare"

        handler: ( handler ) ->
          return pushHandler handler, "prepare"
      },
      {
        ###
        # DOM 加载完成时调用的处理函数
        #
        # @method  ready
        # @param   handler {Function}
        # @return
        ###
        name: "ready"

        handler: ( handler ) ->
          return pushHandler handler, "ready"
      }
    ]

  # Web API 数据载体
  storage.web_api = {}
  # Web API 版本
  storage.config.api = ""
  # 获取存在于内部的 Web API 的命名空间字符串（Namespace String）
  storage.fn.init.apiNS = ( key ) ->

  I18n = new Storage "I18n"

  I18n.config
    formatRegExp: /\{%\s*([A-Z0-9_]+)\s*%\}/ig
    value: ( val ) ->
      return if __proj.isString(val) then val else ""

  API = new Storage "Web_API"

  API.config
    formatRegExp: /\:([a-z_]+)/g
    value: ( val ) ->
      return apiVer() + val ? ""

  route = new Storage "route"

  route.config formatRegExp: /\:([a-z_]+)/g

  asset = new Storage "asset"

  ###
  # 设置初始化函数
  # 
  # @private
  # @method   initialize
  # @return
  ###
  initialize = ->
    args = arguments
    func = args[0]
    key = args[1]

    if __proj.isPlainObject func
      __proj.each func, initialize
    else if __proj.isString(key) and __proj.hasProp(key, storage.fn.init) and __proj.isFunction func
      storage.fn.init[key] = func

  ###
  # 获取 Web API 版本
  # 
  # @private
  # @method   apiVer
  # @return   {String}
  ###
  apiVer = ->
    ver = __proj.config "api"

    return if __proj.isString(ver) && __proj.trim(ver) isnt "" then "/#{ver}" else ""

  storageHandler = ( type, key, map ) ->
    switch type
      when "api"
        obj = API
        getKey = ( k ) ->
          return initializer("apiNS")(k) ? k
      when "route"
        obj = route
      when "asset"
        obj = asset

    # 设置
    if __proj.isPlainObject key
      obj.set key
    # 获取
    else if __proj.isString key
      result = obj.get (if getKey? then getKey(key) else key), map

    return result ? null

  apiHandler = ( key, map ) ->
    return storageHandler "api", key, map

  routeHandler = ( key, map ) ->
    return storageHandler "route", key, map

  assetHandler = ( key ) ->
    return storageHandler "asset", key

  storage.modules.configuration =
    handlers: [
      {
        ###
        # 获取系统信息
        # 
        # @method  config
        # @param   [key] {String}
        # @return  {Object}
        ###
        name: "config"

        handler: ( key ) ->
          return if @isString(key) then storage.config[key] else clone storage.config
      },
      {
        ###
        # 设置初始化信息
        # 
        # @method  init
        # @return
        ###
        name: "init"

        handler: ->
          return initialize.apply window, @slice arguments
      },
      {
        ###
        # 设置及获取国际化信息
        # 
        # @method   i18n
        # @param    key {String}
        # @param    [map] {Plain Object}
        # @return   {String}
        ###
        name: "i18n"

        handler: ( key, map ) ->
          args = arguments

          # 批量存储
          # 调用方式：func({})
          if @isPlainObject key
            I18n.set key
          else if REG_NAMESPACE.test key
            # 单个存储（用 namespace 格式字符串）
            if args.length is 2 and @isString(map) and not REG_NAMESPACE.test map
              # to do sth.
            # 取出并进行格式替换
            else
              if @isPlainObject map
                result = I18n.get key, map
              # 拼接多个数据
              else
                result = ""

                @each args, ( txt ) ->
                  result += I18n.get txt if __proj.isString(txt) and REG_NAMESPACE.test txt

          return result ? null
      },
      {
        ###
        # 设置及获取 Web API
        # 
        # @method   api
        # @param    key {String}
        # @param    [map] {Plain Object}
        # @return   {String}
        ###
        name: "api"

        handler: apiHandler
      },
      {
        ###
        # 设置及获取页面 URL
        # 
        # @method   route
        # @param    key {String}
        # @param    [map] {Plain Object}
        # @return   {String}
        ###
        name: "route"

        handler: routeHandler
      },
      {
        ###
        # 设置及获取资源 URL
        # 
        # @method   asset
        # @param    key {String}
        # @return   {String}
        ###
        name: "asset"

        handler: assetHandler
      }
    ]

  ###
  # 通过 HTML 构建 dataset
  # 
  # @private
  # @method  constructDatasetByHTML
  # @param   html {HTML}   Node's outer html string
  # @return  {JSON}
  ###
  constructDatasetByHTML = ( html ) ->
    dataset = {}
    fragment = html.match /<[a-z]+[^>]*>/i

    if fragment isnt null
      __proj.each fragment[0].match(/(data(-[a-z]+)+=[^\s>]*)/ig) || [], ( attr ) ->
        attr = attr.match /data-(.*)="([^\s"]*)"/i
        dataset[__proj.camelCase attr[1]] = attr[2]
        return true

    return dataset

  ###
  # 通过属性列表构建 dataset
  # 
  # @private
  # @method  constructDatasetByAttributes
  # @param   attributes {NodeList}   Attribute node list
  # @return  {JSON}
  ###
  constructDatasetByAttributes = ( attributes ) ->
    dataset = {}

    __proj.each attributes, ( attr ) ->
      dataset[__proj.camelCase match(1)] = attr.nodeValue if attr.nodeType is ATTRIBUTE_NODE and (match = attr.nodeName.match /^data-(.*)$/i)
      return true

    return dataset

  storage.modules.storage =
    handlers: [
      {
        ###
        # 获取 DOM 的「data-*」属性集或存储数据到内部/从内部获取数据
        # 
        # @method  data
        # @return  {Object}
        ###
        name: "data"

        handler: ->
          args = arguments
          length = args.length

          if length > 0
            target = args[0]

            try
              # 当 target 是包含有 "@" 的字符串时会抛出异常。
              # Error: Syntax error, unrecognized expression: @
              node = $(target).get(0)
            catch error
              node = target

            # 获取 DOM 的「data-*」属性集
            if node and node.nodeType is ELEMENT_NODE
              result = {}

              if node.dataset
                result = node.dataset
              else if node.outerHTML
                result = constructDatasetByHTML node.outerHTML
              else if node.attributes and $.isNumeric node.attributes.length
                result = constructDatasetByAttributes node.attributes
            # 存储数据到内部/从内部获取数据
            else
              if @isString(target) and REG_NAMESPACE.test(target)
                result = if length is 1 then getStorageData(target) else setStorageData target, args[1]

                # 将访问的 key 锁住，在第一次设置之后无法再读写到内部
                limit(target.split(".")[0]) if length > 1 and last(args) is true
              # 有可能覆盖被禁止存取的内部 key，暂时不允许批量添加
              # else {
              #   @each(args, function( n ) {
              #     $.extend(storage, n);
              #   });
              # }

          return result ? null
      },
      {
        ###
        # Save data
        ###
        name: "save"

        handler: ->
          args = arguments
          key = args[0]
          val = args[1]

          # Use localStorage
          if support.storage
            if @isString key
              oldVal = this.access key

              localStorage.setItem key, escape @stringify if @isPlainObject(oldVal) and @isPlainObject(val) then @mixin(true, oldVal, val) else val
          # Use cookie
          # else

          return

        validator: ->
          return arguments.length > 1
      },
      {
        ###
        # Access data
        ###
        name: "access"

        handler: ->
          key = arguments[0]

          # localStorage
          if support.storage
            result = localStorage.getItem key

            if result?
              if result is "undefined"
                result = undefined
              else if result is "null"
                result = null
              else
                result = unescape result

                try
                  result = JSON.parse result
                catch error
                  result = result
            else
              result = undefined
          # Cookie
          # else

          return result

        value: undefined

        validator: ( key ) ->
          return @isString key
      }
      # ,
      # {
      #   name: "clear"

      #   handler: ->
      # }
    ]

  ###
  # AJAX & SJAX 请求处理
  # 
  # @private
  # @method  request
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数
  # @param   fail {Function}           请求失败时的回调函数
  # @param   synch {Boolean}           是否为同步，默认为异步
  # @return  {Object}
  ###
  request = ( options, succeed, fail, synch ) ->
    # 无参数时跳出
    if arguments.length is 0
      return
    
    # 当 options 不是纯对象时将其当作 url 来处理（不考虑其变量类型）
    options = url: options if __proj.isPlainObject(options) is false
    handlers = initializer("ajaxHandler") succeed, fail
    options.success = handlers.success if not __proj.isFunction options.success
    options.error = handlers.error if not __proj.isFunction options.error

    return $.ajax $.extend options, async: synch isnt true

  storage.modules.request =
    handlers: [
      {
        ###
        # Asynchronous JavaScript and XML
        # 
        # @method  ajax
        # @param   options {Object/String}   请求参数列表/请求地址
        # @param   succeed {Function}        请求成功时的回调函数
        # @param   fail {Function}           请求失败时的回调函数
        # @return
        ###
        name: "ajax"

        handler: ( options, succeed, fail ) ->
          return request options, succeed, fail
      },
      {
        ###
        # Synchronous JavaScript and XML
        # 
        # @method  sjax
        # @param   options {Object/String}   请求参数列表/请求地址
        # @param   succeed {Function}        请求成功时的回调函数
        # @param   fail {Function}           请求失败时的回调函数
        # @return
        ###
        name: "sjax"

        handler: ( options, succeed, fail ) ->
          return request options, succeed, fail, true
      }
    ]

  # 补全 pathname 的开头斜杠
  # IE 中 pathname 开头没有斜杠（参考：http://msdn.microsoft.com/en-us/library/ms970635.aspx）
  resolvePathname = ( pathname ) ->
    return if pathname.charAt(0) is "\/" then pathname else "\/#{pathname}"

  # key/value 字符串转换为对象
  str2obj = ( kvStr ) ->
    obj = {}

    __proj.each kvStr.split("&"), ( str ) ->
      str = str.split("=")
      obj[str[0]] = str[1] if __proj.trim(str[0]) isnt ""

    return obj

  storage.modules.URL =
    handlers: [
      {
        ###
        # 获取 URL 的 pathname
        #
        # @method   pathname
        # @param    url {String}
        # @return   {String}
        ###
        name: "pathname"

        handler: ( url ) ->
          return resolvePathname if @isString(url) then url else location.pathname
      },
      {
        name: "url"

        handler: ->
          loc = window.location
          search = loc.search[1..]
          hash = loc.hash[1..]

          return {search, hash, query: str2obj(search), hashMap: str2obj(hash)}
      },
      {
        ###
        # Save web resource to local disk
        #
        # @method  download
        # @param   fileURL {String}
        # @param   fileName {String}
        # @return
        ###
        name: "download"

        handler: ( fileURL, fileName ) ->
          # for non-IE
          if not window.ActiveXObject
            save = document.createElement "a"

            save.href = fileURL
            save.target = "_blank"
            save.download = fileName || "unknown"

            event = document.createEvent "Event"
            event.initEvent "click", true, true
            save.dispatchEvent event
            (window.URL || window.webkitURL).revokeObjectURL save.href
          # for IE
          else if !! window.ActiveXObject && document.execCommand
            _window = window.open fileURL, "_blank"
            
            _window.document.close()
            _window.document.execCommand "SaveAs", true, fileName || fileURL
            _window.close()
      }
    ]

  __proj.extend storage.modules, __proj

  __proj.api.formatList = ( map ) ->
    API.config keys: map if __proj.isPlainObject map

  __proj.route.formatList = ( map ) ->
    route.config keys: map if __proj.isPlainObject map

  __proj.mixin new Environment

  exposeClasses()

  return __proj
  
__proj.mask "Tatami"
__proj.mixin __proj.__meta__, {name: "Tatami", version: "0.2.3"}
