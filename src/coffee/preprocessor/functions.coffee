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
