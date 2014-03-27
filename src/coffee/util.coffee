$.extend _H,
  ###
  # 自定义警告提示框
  #
  # @method  alert
  # @param   message {String}
  # @param   [callback] {Function}
  # @return  {Boolean}
  ###
  alert: ( message, callback ) ->
    return systemDialog "alert", message, callback
  
  ###
  # 自定义确认提示框（两个按钮）
  #
  # @method  confirm
  # @param   message {String}
  # @param   [ok] {Function}       Callback for 'OK' button
  # @param   [cancel] {Function}   Callback for 'CANCEL' button
  # @return  {Boolean}
  ###
  confirm: ( message, ok, cancel ) ->
    return systemDialog "confirm", message, ok, cancel
  
  ###
  # 自定义确认提示框（两个按钮）
  #
  # @method  confirm
  # @param   message {String}
  # @param   [ok] {Function}       Callback for 'OK' button
  # @param   [cancel] {Function}   Callback for 'CANCEL' button
  # @return  {Boolean}
  ###
  confirmEX: ( message, ok, cancel ) ->
    return systemDialog "confirmEX", message, ok, cancel

  ###
  # 将外部处理函数引入到沙盒中
  # 
  # @method  queue
  # @return
  ###
  queue: ->
    return bindHandler.apply window, slicer arguments
  
  ###
  # 执行指定函数
  # 
  # @method  run
  # @return  {Variant}
  ###
  run: ->
    return runHandler.apply window, slicer arguments

  url: ->
    loc = window.location
    url =
      search: loc.search.substring(1)
      hash: loc.hash.substring(1)
      query: {}

    $.each url.search.split("&"), ( i, str ) ->
      str = str.split("=")
      url.query[str[0]] = str[1] if $.trim(str[0]) isnt ""

    return url

  ###
  # Save web resource to local disk
  #
  # @method  download
  # @param   fileURL {String}
  # @param   fileName {String}
  # @return
  ###
  download: ( fileURL, fileName ) ->
    # for non-IE
    if not window.ActiveXObject
      save = document.createElement "a"

      save.href = fileURL
      save.target = "_blank"
      save.download = fileName || "unknown"

      event = document.createEvent "Event"
      event.initEvent "click", true, true
      save.dispatchEvent event
      (window.URL || window.webkitURL).revokeObjectURL save.href
    # for IE
    else if !! window.ActiveXObject && document.execCommand
      _window = window.open fileURL, "_blank"
      
      _window.document.close()
      _window.document.execCommand "SaveAs", true, fileName || fileURL
      _window.close()

  ###
  # Determines whether a function has been defined
  #
  # @method  functionExists
  # @param   funcName {String}
  # @param   isWindow {Boolean}
  # @return  {Boolean}
  ###
  functionExists: ( funcName, isWindow ) ->
    return isExisted (if isWindow is true then window else storage.fn.handler), funcName, "function"

  ###
  # 用指定占位符填补字符串
  # 
  # @method  pad
  # @param   string {String}         源字符串
  # @param   length {Integer}        生成字符串的长度，正数为在后面补充，负数则在前面补充
  # @param   placeholder {String}    占位符
  # @return  {String}
  ###
  pad: ( string, length, placeholder ) ->
    if $.type(string) of { string: true, number: true }
      # 占位符只能指定为一个字符
      # 占位符默认为空格
      placeholder = "\x20" if $.type(placeholder) isnt "string" or placeholder.length isnt 1
      # Set length to 0 if it isn't an integer.
      length = 0 if not ($.isNumeric(length) and /^-?[1-9]\d*$/.test(length))
      string = String string
      index = 1
      unit = String placeholder
      len = Math.abs(length) - string.length

      if len > 0
        # 补全占位符
        while index < len
          placeholder += unit
          index++

        string = if length > 0 then string + placeholder else placeholder + string

    return string

  ###
  # 补零（前导零）
  # 
  # @method  zerofill
  # @param   number {Number}   源数字
  # @param   digit {Integer}   数字位数，正数为在后面补充，负数则在前面补充
  # @return  {String}
  ###
  zerofill: ( number, digit ) ->
    result = ""

    if $.isNumeric(number) and $.isNumeric(digit) and /^-?[1-9]\d*$/.test digit
      rfloat = /^([-+]?\d+)\.(\d+)$/
      isFloat = rfloat.test number
      prefix = ""

      digit = parseInt digit

      # 浮点型数字时 digit 则为小数点后的位数
      if digit > 0 and isFloat
        number = "#{number}".match rfloat
        prefix = "#{number[1] * 1}."
        number = number[2]
      # Negative number
      else if number * 1 < 0
        prefix = "-"
        number = "#{number}".substring(1)

      result = this.pad number, digit, "0"

      if digit < 0 and isFloat
        result = ""
      else
        result = prefix + result

    return result
