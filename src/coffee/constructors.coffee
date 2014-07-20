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

  getData = ( host, key, map ) ->
    __util.each key.split("."), ( part ) ->
      r = hasProp part, host
      host = host[part]

      return r

    s = @settings
    map = {} if not isPlainObj map
    keys = if isPlainObj(s.keys) then s.keys else {}
    regexp = s.formatRegExp
    result = s.value(host)

    if __util.isRegExp regexp
      result = result.replace regexp, ( m, k ) =>
        # 以传入的值为优先
        if hasProp k, map
          r = map[k]
        # 预先设置的值
        else if hasProp k, keys
          r = keys[k]
        else
          r = m

        return if __util.isFunction(r) then r() else r

    return result

  class Storage
    constructor: ( namespace ) ->
      @settings =
        formatRegExp: null
        allowKeys: false
        keys: {}
        value: ( v ) ->
          return v ? ""

      @storage = if isNamespaceStr(namespace) then str2obj("#{namespace}") else storage

    set: ( data ) ->
      __util.mixin @storage, data

    get: ( key, map ) ->
      if __util.isString key
        data = getData.apply this, [@storage, key, map]
      else if @settings.allowKeys is true
        data = __util.keys @storage

      return data ? null

    config: ( settings ) ->
      __util.mixin @settings, settings

  return Storage

Environment = do ( __util ) ->
  nav = navigator
  ua = nav.userAgent.toLowerCase()

  suffix =
    windows:
      "5.1": "XP"
      "5.2": "XP x64 Edition"
      "6.0": "Vista"
      "6.1": "7"
      "6.2": "8"
      "6.3": "8.1"

  platformName = ->
    name = /^[\w.\/]+ \(([^;]+?)[;)]/.exec(ua)[1].split(" ").shift()
    return if name is "compatible" then "windows" else name

  platformVersion = ->
    return (/windows nt ([\w.]+)/.exec(ua) or
            /os ([\w]+) like mac/.exec(ua) or
            /mac os(?: [a-z]*)? ([\w.]+)/.exec(ua) or
            [])[1]?.replace /_/g, "."

  detectPlatform = ->
    platform =
      touchable: false
      version: platformVersion()
    
    platform[platformName()] = true

    if platform.windows
      platform.version = suffix.windows[platform.version]
      platform.touchable = /trident[ \/][\w.]+; touch/.test ua
    else if platform.ipod or platform.iphone or platform.ipad
      platform.touchable = platform.ios = true

    return platform

  # jQuery 1.9.x 以下版本中 jQuery.browser 的实现方式
  # IE 只能检测 IE11 以下
  jQueryBrowser = ->
    browser = {}
    match = /(chrome)[ \/]([\w.]+)/.exec(ua) or
            /(webkit)[ \/]([\w.]+)/.exec(ua) or
            /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(ua) or
            /(msie) ([\w.]+)/.exec(ua) or
            ua.indexOf("compatible") < 0 and /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(ua) or
            []
    result =
      browser: match[1] or ""
      version: match[2] or "0"

    if result.browser
      browser[result.browser] = true
      browser.version = result.version

    if browser.chrome
      browser.webkit = true
    else if browser.webkit
      browser.safari = true

    return browser

  detectBrowser = ->
    # IE11 及以上
    match = /trident.*? rv:([\w.]+)/.exec(ua)

    if match
      browser =
        msie: true
        version: match[1]
    else
      browser = jQueryBrowser()

      if browser.mozilla
        browser.firefox = true
        match = /firefox[ \/]([\w.]+)/.exec(ua)
        browser.version = match[1] if match

    return browser

  # Create an ActiveXObject (IE specified)
  createAXO = ( type ) ->
    try
      axo = new ActiveXObject type
    catch e
      axo = null

    return axo

  hasReaderActiveX = ->
    if __util.hasProp "ActiveXObject"
      axo = createAXO "AcroPDF.PDF"
      axo = createAXO "PDF.PdfCtrl" if not axo

    return axo?

  hasReader = ->
    result = false

    __util.each nav.plugins, ( plugin ) ->
      result = /Adobe Reader|Adobe PDF|Acrobat/gi.test plugin.name
      return not result

    return result

  hasGeneric = ->
    return nav.mimeTypes["application/pdf"]?.enabledPlugin?

  PDFReader = ->
    return hasReader() or hasReaderActiveX() or hasGeneric()
     
  class Environment
    constructor: ->
      @platform = detectPlatform()
      @browser = detectBrowser()
      @plugins =
        # refer: https://github.com/pipwerks/PDFObject/blob/master/pdfobject.js
        pdf: PDFReader()

  return Environment
