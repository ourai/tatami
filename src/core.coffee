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
    # Web API 版本
    api: ""
    lang: (document.documentElement.lang ||
      document.documentElement.getAttribute("lang") ||
      navigator.language ||
      navigator.browserLanguage).split("-")[0]
    path: currentPath()

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
      # 系统对话框创建后
      systemDialog: $.noop
      # Ajax 请求
      ajaxHandler: ( succeed, fail ) ->
        return {
          # 状态码为 200
          success: ( data, textStatus, jqXHR ) ->
            args = slicer arguments
            ###
            # 服务端在返回请求结果时必须是个 JSON，如下：
            #    {
            #      "code": {Integer}       # 处理结果代码，code > 0 为成功，否则为失败
            #      "message": {String}     # 请求失败时的提示信息
            #    }
            ###
            if data.code > 0
              succeed.apply($, args) if $.isFunction succeed
            else
              if $.isFunction fail
                fail.apply $, args
              # 默认弹出警告对话框
              else
                systemDialog "alert", data.message
          # 状态码为非 200
          error: $.noop
        }
    handler: {}

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
  # 国际化
  #
  # @property  i18n
  # @type      {Object}
  ###
  i18n:
    _SYS:
      dialog:
        zh:
          title: "系统提示"
          close: "关闭"
          ok: "确定"
          cancel: "取消"
          yes: "是"
          no: "否"
        en:
          title: "System"
          close: "Close"
          ok: "Ok"
          cancel: "Cancel"
          yes: "Yes"
          no: "No"

  ###
  # Web API
  #
  # @property  api
  # @type      {Object}
  ###
  web_api: {}

$.extend _H,
  ###
  # ======================================
  #  核心方法
  # ======================================
  ###
  ###
  # 更改 LIB_CONFIG.name 以适应项目「本土化」
  # 
  # @method   mask
  # @param    guise {String}    New name for library
  # @return   {Boolean}
  ###
  mask: ( guise ) ->
    result = false

    if $.type(guise) is "string"
      if window.hasOwnProperty guise
        console.error "'#{guise}' has existed as a property of Window object." if window.console
      else
        window[guise] = window[LIB_CONFIG.name]
        result = delete window[LIB_CONFIG.name]
        LIB_CONFIG.name = guise

    return result

  ###
  # 自定义警告提示框
  #
  # @method  alert
  # @param   message {String}
  # @param   [callback] {Function}
  # @return  {Boolean}
  ###
  alert: ( message, callback ) ->
    return systemDialog "alert", message, callback
  
  ###
  # 自定义确认提示框（两个按钮）
  #
  # @method  confirm
  # @param   message {String}
  # @param   [ok] {Function}       Callback for 'OK' button
  # @param   [cancel] {Function}   Callback for 'CANCEL' button
  # @return  {Boolean}
  ###
  confirm: ( message, ok, cancel ) ->
    return systemDialog "confirm", message, ok, cancel
  
  ###
  # 自定义确认提示框（两个按钮）
  #
  # @method  confirm
  # @param   message {String}
  # @param   [ok] {Function}       Callback for 'OK' button
  # @param   [cancel] {Function}   Callback for 'CANCEL' button
  # @return  {Boolean}
  ###
  confirmEX: ( message, ok, cancel ) ->
    return systemDialog "confirmEX", message, ok, cancel

  ###
  # 沙盒
  #
  # 封闭运行环境的开关，每个页面只能运行一次
  # 
  # @method  sandbox
  # @param   setting {Object}      系统环境配置
  # @return  {Object/Boolean}      （修改后的）系统环境配置
  ###
  sandbox: ( setting ) ->
    if storage.sandboxStarted isnt true
      # 返回值为修改后的系统环境配置
      result = resetConfig setting

      # 全局配置
      # setup();
      # DOM tree 构建前的函数队列
      runHandler storage.fn.prepare
      
      # DOM tree 构建后的函数队列
      $(document).ready ->
        runHandler storage.fn.ready
      
      storage.sandboxStarted = true
    
    return result || false

  ###
  # DOM 未加载完时调用的处理函数
  # 主要进行事件委派等与 DOM 加载进程无关的操作
  #
  # @method  prepare
  # @param   handler {Function}
  # @return
  ###
  prepare: ( handler ) ->
    return pushHandler handler, "prepare"

  ###
  # DOM 加载完成时调用的处理函数
  #
  # @method  ready
  # @param   handler {Function}
  # @return
  ###
  ready: ( handler ) ->
    return pushHandler handler, "ready"

  ###
  # 设置初始化信息
  # 
  # @method  init
  # @return
  ###
  init: ->
    return initialize.apply window, slicer arguments

  ###
  # 获取系统信息
  # 
  # @method  config
  # @param   [key] {String}
  # @return  {Object}
  ###
  config: ( key ) ->
    return if $.type(key) is "string" then storage.config[key] else clone storage.config

  ###
  # Asynchronous JavaScript and XML
  # 
  # @method  ajax
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数（code > 0）
  # @param   fail {Function}           请求失败时的回调函数（code <= 0）
  # @return
  ###
  ajax: ( options, succeed, fail ) ->
    return request options, succeed, fail
  
  ###
  # Synchronous JavaScript and XML
  # 
  # @method  sjax
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数（code > 0）
  # @param   fail {Function}           请求失败时的回调函数（code <= 0）
  # @return
  ###
  sjax: ( options, succeed, fail ) ->
    return request options, succeed, fail, true
  
  ###
  # 将外部处理函数引入到沙盒中
  # 
  # @method  queue
  # @return
  ###
  queue: ->
    return bindHandler.apply window, slicer arguments
  
  ###
  # 执行指定函数
  # 
  # @method  run
  # @return  {Variant}
  ###
  run: ->
    return runHandler.apply window, slicer arguments

  ###
  # 获取 DOM 的「data-*」属性集或存储数据到内部/从内部获取数据
  # 
  # @method  data
  # @return  {Object}
  ###
  data: ->
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
        if typeof target is "string" and REG_NAMESPACE.test(target)
          result = if length is 1 then getStorageData(target) else setStorageData target, args[1]

          # 将访问的 key 锁住，在第一次设置之后无法再读写到内部
          limit(target.split(".")[0]) if length > 1 and last(args) is true
        # 有可能覆盖被禁止存取的内部 key，暂时不允许批量添加
        # else {
        #   $.each(args, function( i, n ) {
        #     $.extend(storage, n);
        #   });
        # }

    return result || null

  ###
  # 设置及获取国际化信息
  # 
  # @method  i18n
  # @return  {String}
  ###
  i18n: ->
    args = arguments
    key = args[0]
    result = null

    # 批量存储
    # 调用方式：func({})
    if $.isPlainObject key
      $.extend storage.i18n, key
    else if REG_NAMESPACE.test key
      data = args[1]

      # 单个存储（用 namespace 格式字符串）
      if args.length is 2 and typeof data is "string" and not REG_NAMESPACE.test data
        # to do sth.
      # 取出并进行格式替换
      else if $.isPlainObject data
        result = getStorageData "i18n.#{key}", true
        result = (if typeof result is "string" then result else "").replace  /\{%\s*([A-Z0-9_]+)\s*%\}/ig, ( txt, k ) ->
          return data[k]
      # 拼接多个数据
      else
        result = ""

        $.each args, ( i, txt ) ->
          if typeof txt is "string" and REG_NAMESPACE.test txt
            r = getStorageData "i18n.#{txt}", true
            result += (if typeof r is "string" then r else "")

    return result

  ###
  # 设置及获取 Web API
  # 
  # @method  api
  # @return  {String}
  ###
  api: ->
    args = arguments
    key = args[0]
    result = null

    if $.isPlainObject key
      $.extend storage.web_api, key
    else if $.type(key) is "string"
      regexp = /^([a-z]+)_/
      match = (key.match(regexp) ? [])[1]
      data = args[1]
      type = undefined

      $.each ["front", "admin"], ( i, n ) ->
        if match is n
          type = n
          return false

      if type
        key = key.replace regexp, ""
      else
        type = "common"

      api_ver = this.config "api"

      if $.type(api_ver) is "string" && $.trim(api_ver) isnt ""
        api_ver = "/" + api_ver
      else
        api_ver = ""

      result = api_ver + getStorageData "web_api.#{type}.#{key}", true

      if $.isPlainObject data
        result = result.replace /\:([a-z_]+)/g, ( m, k ) ->
          return data[k]

    return result

  ###
  # Save data
  ###
  save: ->
    args = arguments
    key = args[0]
    val = args[1]

    # Use localStorage
    if support.storage
      if typeof key is "string"
        oldVal = this.access key

        localStorage.setItem key, escape if $.isPlainObject(oldVal) then JSON.stringify($.extend oldVal, val) else val
    # Use cookie
    # else

  ###
  # Access data
  ###
  access: ->
    key = arguments[0]

    if typeof key is "string"
      # localStorage
      if support.storage
        result = localStorage.getItem key

        if result isnt null
          result = unescape result

          try
            result = JSON.parse result
          catch error
            result = result
      # Cookie
      # else

    return result || null

  # clear: ->

  url: ->
    loc = window.location
    url =
      search: loc.search.substring(1)
      hash: loc.hash.substring(1)
      query: {}

    $.each url.search.split("&"), ( i, str ) ->
      str = str.split("=")
      url.query[str[0]] = str[1] if $.trim(str[0]) isnt ""

    return url

  ###
  # Save web resource to local disk
  #
  # @method  download
  # @param   fileURL {String}
  # @param   fileName {String}
  # @return
  ###
  download: ( fileURL, fileName ) ->
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

  ###
  # Determines whether a function has been defined
  #
  # @method  functionExists
  # @param   funcName {String}
  # @param   isWindow {Boolean}
  # @return  {Boolean}
  ###
  functionExists: ( funcName, isWindow ) ->
    return isExisted (if isWindow is true then window else storage.fn.handler), funcName, "function"

  ###
  # 用指定占位符填补字符串
  # 
  # @method  pad
  # @param   string {String}         源字符串
  # @param   length {Integer}        生成字符串的长度，正数为在后面补充，负数则在前面补充
  # @param   placeholder {String}    占位符
  # @return  {String}
  ###
  pad: ( string, length, placeholder ) ->
    if $.type(string) of { string: true, number: true }
      # 占位符只能指定为一个字符
      # 占位符默认为空格
      placeholder = "\x20" if $.type(placeholder) isnt "string" or placeholder.length isnt 1
      # Set length to 0 if it isn't an integer.
      length = 0 if not ($.isNumeric(length) and /^-?[1-9]\d*$/.test(length))
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

  ###
  # 补零（前导零）
  # 
  # @method  zerofill
  # @param   number {Number}   源数字
  # @param   digit {Integer}   数字位数，正数为在后面补充，负数则在前面补充
  # @return  {String}
  ###
  zerofill: ( number, digit ) ->
    result = ""

    if $.isNumeric(number) and $.isNumeric(digit) and /^-?[1-9]\d*$/.test digit
      rfloat = /^([-+]?\d+)\.(\d+)$/
      isFloat = rfloat.test number
      prefix = ""

      digit = parseInt digit

      # 浮点型数字时 digit 则为小数点后的位数
      if digit > 0 and isFloat
        number = "#{number}".match rfloat
        prefix = "#{number[1] * 1}."
        number = number[2]
      # Negative number
      else if number * 1 < 0
        prefix = "-"
        number = "#{number}".substring(1)

      result = this.pad number, digit, "0"

      if digit < 0 and isFloat
        result = ""
      else
        result = prefix + result

    return result
