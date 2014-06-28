# Web API 数据载体
storage.web_api = {}
# Web API 版本
storage.config.api = ""
# 获取存在于内部的 Web API 的命名空间字符串（Namespace String）
storage.fn.init.apiNS = ( key ) ->

I18n = new Storage "I18n"

I18n.config
  format_regexp: /\{%\s*([A-Z0-9_]+)\s*%\}/ig
  value: ( val ) ->
    return if _H.isString(val) then val else ""

API = new Storage "Web_API"

API.config
  format_regexp: /\:([a-z_]+)/g
  value: ( val ) ->
    return api_ver() + val ? ""

route = new Storage "route"

route.config format_regexp: /\:([a-z_]+)/g

###
# 设置初始化函数
# 
# @private
# @method   initialize
# @return
###
initialize = ->
  args = arguments
  func = args[0]
  key = args[1]

  if _H.isPlainObject func
    _H.each func, initialize
  else if _H.isString(key) and _H.hasProp(key, storage.fn.init) and _H.isFunction func
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

  return if _H.isString(ver) && _H.trim(ver) isnt "" then "/#{ver}" else ""

_H.mixin
  ###
  # 获取系统信息
  # 
  # @method  config
  # @param   [key] {String}
  # @return  {Object}
  ###
  config: ( key ) ->
    return if @isString(key) then storage.config[key] else clone storage.config
  
  ###
  # 设置初始化信息
  # 
  # @method  init
  # @return
  ###
  init: ->
    return initialize.apply window, @slice arguments

  ###
  # 设置及获取国际化信息
  # 
  # @method   i18n
  # @param    key {String}
  # @param    [map] {Plain Object}
  # @return   {String}
  ###
  i18n: ( key, map ) ->
    args = arguments

    # 批量存储
    # 调用方式：func({})
    if @isPlainObject key
      I18n.set key
    else if REG_NAMESPACE.test key
      # 单个存储（用 namespace 格式字符串）
      if args.length is 2 and @isString(map) and not REG_NAMESPACE.test map
        # to do sth.
      # 取出并进行格式替换
      else
        if @isPlainObject map
          result = I18n.get key, map
        # 拼接多个数据
        else
          result = ""

          @each args, ( txt ) ->
            result += I18n.get txt if _H.isString(txt) and REG_NAMESPACE.test txt

    return result ? null

  ###
  # 设置及获取 Web API
  # 
  # @method   api
  # @param    key {String}
  # @param    [map] {Plain Object}
  # @return   {String}
  ###
  api: ( key, map ) ->
    # 设置
    if @isPlainObject key
      API.set key
    # 获取
    else if @isString key
      result = API.get initializer("apiNS")(key) ? key, map

    return result ? null

  route: ( key, map ) ->
    # 设置
    if @isPlainObject key
      route.set key
    # 获取
    else if @isString key
      result = route.get key, map

    return result ? null

_H.api.formatList = ( map ) ->
  API.config keys: map if _H.isPlainObject map

_H.route.formatList = ( map ) ->
  route.config keys: map if _H.isPlainObject map
