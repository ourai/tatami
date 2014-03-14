###
# 设置初始化函数
# 
# @private
# @method   initialize
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
# 获取 Web API 版本
# 
# @private
# @method   api_ver
# @return   {String}
###
api_ver = ->
  ver = _H.config "api"

  if $.type(ver) is "string" && $.trim(ver) isnt ""
    ver = "/" + ver
  else
    ver = ""

  return ver

$.extend _H,
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
  # 获取系统信息
  # 
  # @method  config
  # @param   [key] {String}
  # @return  {Object}
  ###
  config: ( key ) ->
    return if $.type(key) is "string" then storage.config[key] else clone storage.config
  
  ###
  # 设置初始化信息
  # 
  # @method  init
  # @return
  ###
  init: ->
    return initialize.apply window, slicer arguments

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

      result = api_ver() + getStorageData "web_api.#{type}.#{key}", true

      if $.isPlainObject data
        result = result.replace /\:([a-z_]+)/g, ( m, k ) ->
          return data[k]

    return result
