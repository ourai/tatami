Environment = do ( __util ) ->
  nav = navigator

  # jQuery 1.9.x 以下版本中 jQuery.browser 的实现方式
  # IE 只能检测 IE11 以下
  jQueryBrowser = ( ua ) ->
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
    ua = nav.userAgent.toLowerCase()
    # IE11 及以上
    match = /trident.*? rv:([\w.]+)/.exec(ua)

    if match
      browser =
        msie: true
        version: match[1]
    else
      browser = jQueryBrowser ua

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
      @browser = detectBrowser()
      @plugins =
        # refer: https://github.com/pipwerks/PDFObject/blob/master/pdfobject.js
        pdf: PDFReader()

  return Environment
