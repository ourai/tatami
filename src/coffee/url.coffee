# 补全 pathname 的开头斜杠
# IE 中 pathname 开头没有斜杠（参考：http://msdn.microsoft.com/en-us/library/ms970635.aspx）
resolvePathname = ( pathname ) ->
  return if pathname.charAt(0) is "\/" then pathname else "\/#{pathname}"

_H.mixin
  ###
  # 获取 URL 的 pathname
  #
  # @method   pathname
  # @param    url {String}
  # @return   {String}
  ###
  pathname: ( url ) ->
    return resolvePathname if @isString(url) then url else location.pathname
