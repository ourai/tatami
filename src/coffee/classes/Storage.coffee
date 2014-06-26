Storage = do ( __proc ) ->
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

    __proc.each str.split("."), ( part ) ->
      obj[part] = {} if not __proc.hasProp part, obj
      obj = obj[part]

    return obj

  class Storage
    constructor: ( namespace ) ->
      @storage = if isNamespaceStr(namespace) then str2obj("#{namespace}") else storage

    set: ( data ) ->
      __proc.mixin(@storage, data) if __proc.isPlainObject data

    get: ( key, format_map ) ->
      if __proc.isString key
        data = @storage[key]
      else
        data = []
        
        __proc.each @storage, ( v ) ->
          data.push v

      return data

    keys: ( key_map ) ->

  return Storage
