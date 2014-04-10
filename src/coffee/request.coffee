###
# AJAX & SJAX 请求处理
# 
# @private
# @method  request
# @param   options {Object/String}   请求参数列表/请求地址
# @param   succeed {Function}        请求成功时的回调函数
# @param   fail {Function}           请求失败时的回调函数
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

_H.mixin
  ###
  # Asynchronous JavaScript and XML
  # 
  # @method  ajax
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数
  # @param   fail {Function}           请求失败时的回调函数
  # @return
  ###
  ajax: ( options, succeed, fail ) ->
    return request options, succeed, fail
  
  ###
  # Synchronous JavaScript and XML
  # 
  # @method  sjax
  # @param   options {Object/String}   请求参数列表/请求地址
  # @param   succeed {Function}        请求成功时的回调函数
  # @param   fail {Function}           请求失败时的回调函数
  # @return
  ###
  sjax: ( options, succeed, fail ) ->
    return request options, succeed, fail, true
