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

              @each arg.split("."), ( part, idx, parts ) =>
                if not @hasProp part, obj
                  obj[part] = if idx is parts.length - 1 then null else {}
                else if not obj?
                  return false

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
