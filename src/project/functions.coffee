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
