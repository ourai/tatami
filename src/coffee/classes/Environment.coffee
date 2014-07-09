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

  # 平台版本
  platformVersion = ( info ) ->
    return suffix[info.platform]?[info.version]

  # 平台类型（PC/Mobile/Tablet 等）
  platformType = ( info ) ->
    if info.platform is "windows"
      ver = info.version * 1
      type = "pc" if ver < 8 or isNaN(ver)

    return type

  detectPlatform = ->
    platform = {}
    match = /(windows) nt ([\w.]+)/.exec(ua) or
            []
    result =
      platform: match[1] or ""
      version: match[2] or "0"

    if result.platform
      platform[result.platform] = true
      platform.version = platformVersion result
      type = platformType result
      platform[type] = true if type

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
