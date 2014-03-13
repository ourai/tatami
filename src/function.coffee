###
# 获取当前脚本所在目录路径
# 
# @private
# @method  currentPath
# @return  {String}
###
currentPath = ->
  script = last document.scripts
  link = document.createElement "a"
  link.href = if script.hasAttribute then script.src else script.getAttribute "src", 4

  return link.pathname.replace /[^\/]+\.js$/i, ""

###
# 切割 Array Like 片段
#
# @private
# @method  slicer
# @return
###
slicer = ( args, index ) ->
  return [].slice.call args, (Number(index) || 0)

###
# 取得数组或类数组对象中最后一个元素
#
# @private
# @method  last
# @return
###
last = ( array ) ->
  return slicer(array, -1)[0]

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
  #       else if ( $.isFunction(CB_Enter) ) {
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

  if $.type(type) is "string"
    type = type.toLowerCase()

    # jQuery UI Dialog
    if $.isFunction $.fn.dialog
      poolName = "systemDialog"
      i18nText = storage.i18n._SYS.dialog[_H.config "lang"]
      storage.pool[poolName] = {} if not storage.pool.hasOwnProperty poolName
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

                switch $.trim btn.text()
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
          okHandler() if $.isFunction okHandler
        else
          cancelHandler() if $.isFunction cancelHandler

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
  i18nText = storage.i18n._SYS.dialog[_H.config "lang"]
  handler = ( cb, rv ) ->
    $(this).dialog "close"

    cb() if $.isFunction cb

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
  else if typeof name is "string"
    # 保存
    if $.isFunction handler
      fnList[name] = handler
    # 获取
    else
      handler = fnList[name]
  # 传入函数列表
  else if $.isPlainObject name
    fnList[funcName] = func for funcName, func of name when $.isFunction func
    
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
  args = slicer arguments, 1
  func = storage.fn.handler[name]
  result = null
  
  # 指定函数名时，从函数池里提取对应函数
  if typeof name is "string" and $.isFunction func
    result = func.apply window, args
  # 指定函数列表（数组）时
  else if $.isArray name
    func.call window for func in name when $.isFunction func
  
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
  storage.fn[queue].push handler if $.isFunction handler

###
# 重新配置系统参数
# 
# @private
# @method  resetConfig
# @param   setting {Object}      配置参数
# @return  {Object}              （修改后的）系统配置信息
###
resetConfig = ( setting ) ->
  return clone if $.isPlainObject(setting) then $.extend(storage.config, setting) else storage.config

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
  
  if $.isArray(source) or source.length isnt undefined
    result = [].concat [], slicer source
  else if $.isPlainObject source
    result = $.extend true, {}, source
  
  return result

###
# 设置初始化函数
# 
# @private
# @method  initialize
# @return
###
initialize = ->
  args = arguments
  key = args[0]
  func = args[1]

  if $.isPlainObject key
    $.each key, initialize
  else if $.type(key) is "string" and storage.fn.init.hasOwnProperty(key) and $.isFunction func
    storage.fn.init[key] = func

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
# AJAX & SJAX 请求处理
# 
# @private
# @method  request
# @param   options {Object/String}   请求参数列表/请求地址
# @param   succeed {Function}        请求成功时的回调函数（）
# @param   fail {Function}           请求失败时的回调函数（code <= 0）
# @param   synch {Boolean}           是否为同步，默认为异步
# @return  {Object}
###
request = ( options, succeed, fail, synch ) ->
  # 无参数时跳出
  if arguments.length is 0
    return
  
  # 当 options 不是纯对象时将其当作 url 来处理（不考虑其变量类型）
  options = url: options if $.isPlainObject(options) is false
  handlers = initializer("ajaxHandler") succeed, fail
  options.success = handlers.success if not $.isFunction options.success
  options.error = handlers.error if not $.isFunction options.error

  return $.ajax $.extend options, async: synch isnt true

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
    $.each fragment[0].match(/(data(-[a-z]+)+=[^\s>]*)/ig) || [], ( idx, attr ) ->
      attr = attr.match /data-(.*)="([^\s"]*)"/i
      dataset[$.camelCase attr[1]] = attr[2]
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

  $.each attributes, ( idx, attr ) ->
    dataset[$.camelCase match(1)] = attr.nodeValue if attr.nodeType is ATTRIBUTE_NODE and (match = attr.nodeName.match /^data-(.*)$/i)
    return true

  return dataset

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

    $.each parts, ( idx, part ) ->
      rv = result.hasOwnProperty part
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
  isObj = $.isPlainObject data

  if length is 1
    key = parts[0]
    result = setData storage, key, data, storage.hasOwnProperty key
  else
    result = storage

    $.each parts, ( i, n ) ->
      if i < length - 1
        result[n] = {} if not result.hasOwnProperty n
      else
        result[n] = setData result, n, data, $.isPlainObject result[n]
      result = result[n]
      return true

  return result

setData = ( target, key, data, condition ) ->
  if condition && $.isPlainObject data
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
  return $.type(host) is "object" and $.type(prop) is "string" and host.hasOwnProperty(prop) and $.type(host[prop]) is type

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
