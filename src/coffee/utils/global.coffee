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
    lib = this
    plain = lib.isPlainObject base

    if (plain or connate) and strict
      result = target is base
    else
      if plain
        isRun = compareObjects.apply lib, [lib.keys(base), lib.keys(target), false, true]
      else
        isRun = target.length is base.length
      
      if isRun
        lib.each base, ( n, i ) ->
          type = lib.type n

          if lib.inArray(type, ["string", "number", "boolean", "null", "undefined"]) > -1
            return result = target[i] is n
          else if lib.inArray(type, ["date", "regexp", "function"]) > -1
            return result = if strict then target[i] is n else target[i].toString() is n.toString()
          else if lib.inArray(type, ["array", "object"]) > -1
            return result = compareObjects.apply lib, [n, target[i], strict, connate]

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
          lib = this
          ns = {}
          hostObj = args[0]
          
          # Determine the host object.
          (hostObj = if args[args.length - 1] is true then window else this) if not lib.isPlainObject hostObj

          lib.each args, ( arg ) ->
            if lib.isString(arg) and /^[0-9A-Z_.]+[^_.]$/i.test(arg)
              obj = hostObj

              lib.each arg.split("."), ( part, idx, parts ) ->
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

          if arguments.length < 2
            lib = this
            type_b = lib.type( base )

            if lib.type(target) is type_b
              plain_b = lib.isPlainObject base

              if plain_b and lib.isPlainObject(target) or type_b isnt "object"
                # 是否为“天然”的数组（以别于后来将字符串等转换成的数组）
                connate = lib.isArray base

                if not plain_b and not connate
                  base = [base]
                  target = [target]

                # If 'strict' is true, then compare the objects' references, else only compare their values.
                strict = false if not lib.isBoolean strict

                result = compareObjects.apply(lib, [base, target, strict, connate])

          return result
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
          t = @type target

          if t is "object"
            if @isPlainObject target
              try
                result = JSON.stringify target
              catch e
                result = "{#{stringifyCollection.call this, target}}"
            else
              result = ""
          else
            switch t
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
