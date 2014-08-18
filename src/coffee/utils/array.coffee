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
