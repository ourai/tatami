__util = do ( window, __proc ) ->
  
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
          return __proc(data, host)
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
          if @hasProp guise
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

              @each arg.split("."), ( part, idx, parts ) ->
                (obj[ part ] = if idx is parts.length - 1 then null else {}) if obj[part] is undefined
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
      },
      {
        ###
        # Returns the characters in a string beginning at the specified location through the specified number of characters.
        #
        # @method  substr
        # @param   string {String}         The input string. Must be one character or longer.
        # @param   start {Integer}         Location at which to begin extracting characters.
        # @param   length {Integer}        The number of characters to extract.
        # @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
        # @return  {String}
        # 
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/substr
        ###
        name: "substr"

        handler: ( string, start, length, ignore ) ->
          args = arguments
          lib = this

          if args.length is 3 and lib.isNumeric(start) and start > 0 and (lib.isString(length) or lib.isRegExp(length))
            string = ignoreSubStr.apply lib, [string, start, length]
          else if lib.isNumeric(start) and start >= 0
            length = string.length if not lib.isNumeric(length) or length <= 0
            string = if lib.isString(ignore) or lib.isRegExp(ignore) then ignoreSubStr.apply(lib, [string.substring(start), length, ignore]) else string.substring(start, length)

          return string
      }
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
      value:
        name: "__util"
        version: ""
  catch error
    __util.mixin
      __meta__:
        name: "__util"
        version: ""

  return __util
  