Storage = do ( __util ) ->
  storage = {}

  isNamespaceStr = ( str ) ->
    return /^[0-9a-z_.]+[^_.]?$/i.test str

  # setStorageData = ( ns_str, data ) ->
  #   parts = ns_str.split "."
  #   length = parts.length
  #   isObj = _H.isPlainObject data

  #   if length is 1
  #     key = parts[0]
  #     result = setData storage, key, data, _H.hasProp(key, storage)
  #   else
  #     result = storage

  #     _H.each parts, ( n, i ) ->
  #       if i < length - 1
  #         result[n] = {} if not _H.hasProp(n, result)
  #       else
  #         result[n] = setData result, n, data, _H.isPlainObject result[n]
  #       result = result[n]
  #       return true

  #   return result

  # Convert a namespace string to a plain object
  str2obj = ( str ) ->
    obj = storage

    __util.each str.split("."), ( part ) ->
      obj[part] = {} if not __util.hasProp part, obj
      obj = obj[part]

    return obj

  getData = ( host, key, format_map ) ->
    __util.each key.split("."), ( part ) ->
      r = __util.hasProp part, host
      host = host[part]

      return r

    result = host ? ""

    if __util.isPlainObject format_map
      result = result.replace @settings.format_regexp, ( m, k ) =>
        return if __util.hasProp(k, format_map) then format_map[k] else m

    return result

  class Storage
    constructor: ( namespace ) ->
      @storage = if isNamespaceStr(namespace) then str2obj("#{namespace}") else storage
      @settings =
        format_regexp: /.*/g
        allow_keys: false
        keys: {}

    set: ( data ) ->
      __util.mixin @storage, data

    get: ( key, format_map ) ->
      if __util.isString key
        data = getData.apply this, [@storage, key, format_map]
      else if @settings.allow_keys is true
        data = __util.keys @storage

      return data ? null

    config: ( settings ) ->
      __util.mixin @settings, settings

  return Storage
