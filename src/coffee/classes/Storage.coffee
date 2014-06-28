Storage = do ( __util ) ->
  hasProp = __util.hasProp
  isPlainObj = __util.isPlainObject

  storage = {}

  isNamespaceStr = ( str ) ->
    return /^[0-9a-z_.]+[^_.]?$/i.test str

  # Convert a namespace string to a plain object
  str2obj = ( str ) ->
    obj = storage

    __util.each str.split("."), ( part ) ->
      obj[part] = {} if not hasProp part, obj
      obj = obj[part]

    return obj

  getData = ( host, key, format_map ) ->
    __util.each key.split("."), ( part ) ->
      r = hasProp part, host
      host = host[part]

      return r

    s = @settings
    result = s.value host

    if isPlainObj format_map
      keys = if isPlainObj(s.keys) then s.keys else {}
      result = result.replace s.format_regexp, ( m, k ) =>
        # 以传入的值为优先
        if hasProp k, format_map
          r = format_map[k]
        # 预先设置的值
        else if hasProp k, keys
          r = keys[k]
        else
          r = m

        return r  

    return result

  class Storage
    constructor: ( namespace ) ->
      @settings =
        format_regexp: /.*/g
        allow_keys: false
        keys: {}
        value: ( v ) ->
          return v ? ""

      @storage = if isNamespaceStr(namespace) then str2obj("#{namespace}") else storage

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
