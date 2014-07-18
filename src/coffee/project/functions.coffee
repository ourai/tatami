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
  # 生成自定义系统对话框
  # 
  # @private
  # @method  systemDialog
  # @param   type {String}
  # @param   message {String}
  # @param   okHandler {Function}
  # @param   cancelHandler {Function}
  # @return  {Boolean}
  ###
  systemDialog = ( type, message, okHandler, cancelHandler ) ->
    result = false

    if __proj.isString type
      type = type.toLowerCase()

      # jQuery UI Dialog
      if __proj.isFunction $.fn.dialog
        poolName = "systemDialog"
        i18nText = storage.i18n._SYS.dialog[__proj.config "lang"]
        storage.pool[poolName] = {} if not __proj.hasProp(poolName, storage.pool)
        dlg = storage.pool[poolName][type]

        if not dlg
          dlg = $("<div data-role=\"dialog\" data-type=\"system\" />")
            .appendTo $("body")
            .on
              # 初始化后的额外处理
              dialogcreate: initializer "systemDialog"
              # 为按钮添加标记
              dialogopen: ( e, ui ) ->
                $(".ui-dialog-buttonset .ui-button", $(this).closest(".ui-dialog")).each ->
                  btn = $(this)

                  switch __proj.trim btn.text()
                    when i18nText.ok
                      type = "ok"
                    when i18nText.cancel
                      type = "cancel"
                    when i18nText.yes
                      type = "yes"
                    when i18nText.no
                      type = "no"

                  btn.addClass "ui-button-#{type}"
            .dialog
              title: i18nText.title
              width: 400
              minHeight: 100
              closeText: i18nText.close
              modal: true
              autoOpen: false
              resizable: false
              closeOnEscape: false

          storage.pool[poolName][type] = dlg

          # 移除关闭按钮
          dlg.closest(".ui-dialog").find(".ui-dialog-titlebar-close").remove()

        result = systemDialogHandler type, message, okHandler, cancelHandler
      # 使用 window 提示框
      else
        result = true

        if type is "alert"
          window.alert message
        else
          if window.confirm message
            okHandler() if __proj.isFunction okHandler
          else
            cancelHandler() if __proj.isFunction cancelHandler

    return result

  ###
  # 系统对话框的提示信息以及按钮处理
  # 
  # @private
  # @method  systemDialogHandler
  # @param   type {String}             对话框类型
  # @param   message {String}          提示信息内容
  # @param   okHandler {Function}      确定按钮
  # @param   cancelHandler {Function}  取消按钮
  # @return
  ###
  systemDialogHandler = ( type, message, okHandler, cancelHandler ) ->
    i18nText = storage.i18n._SYS.dialog[__proj.config "lang"]
    handler = ( cb, rv ) ->
      $(this).dialog "close"

      cb() if __proj.isFunction cb

      return rv

    btns = []
    btnText =
      ok: i18nText.ok
      cancel: i18nText.cancel
      yes: i18nText.yes
      no: i18nText.no

    dlg = storage.pool.systemDialog[type]
    dlgContent = $("[data-role='dialog-content']", dlg)
    dlgContent = dlg if dlgContent.size() is 0

    # 设置按钮以及其处理函数
    if type is "confirm"
      btns.push
        text: btnText.ok
        click: -> 
          handler.apply this, [okHandler, true]
          return true
      btns.push
        text: btnText.cancel
        click: ->
          handler.apply this, [cancelHandler, false]
          return true
    else if type is "confirmex"
      btns.push
        text: btnText.yes
        click: ->
          handler.apply this, [okHandler, true]
          return true
      btns.push
        text: btnText.no
        click: ->
          handler.apply this, [cancelHandler, false]
          return true
      btns.push
        text: btnText.cancel
        click: ->
          handler.apply this, [null, false]
          return true
    else
      type = "alert"

      if okHandler isnt null
        btns.push
          text: btnText.ok,
          click: ->
            handler.apply this, [okHandler, true]
            return true
      else
        btns = null

    # 提示信息内容
    dlgContent.html message || ""

    # 添加按钮并打开对话框
    dlg
      .dialog "option", "buttons", btns
      .dialog "open"

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
      fnList[funcName] = func for funcName, func of name when __proj.isFunction func
      
    return handler

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
    result = null
    
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

  exposeClasses = ->
    classes =
      Storage: Storage

    try
      Object.defineProperty __proj, "__class__",
        __proto__: null
        value: classes
    catch error
      __proj.mixin __class__: classes
