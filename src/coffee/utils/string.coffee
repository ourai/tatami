  # ====================
  # String
  # ====================

  ###
  # Ignore specified strings.
  #
  # @private
  # @method  ignoreSubStr
  # @param   string {String}         The input string. Must be one character or longer.
  # @param   length {Integer}        The number of characters to extract.
  # @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
  # @return  {String}
  ###
  ignoreSubStr = ( string, length, ignore ) ->
    lib = this;
    exp = if lib.isRegExp(ignore) then ignore else new RegExp(ignore, "ig")

    exp = new RegExp(exp.source, "ig") if not exp.global

    result = exp.exec string

    while result
      length += result[0].length if result.index < length
      result.lastIndex = 0

    return string.substring 0, length

  ###
  # 将字符串转换为以 \u 开头的十六进制 Unicode
  # 
  # @private
  # @method  unicode
  # @param   string {String}
  # @return  {String}
  ###    
  unicode = ( string ) ->
    lib = this
    result = []
    result = ("\\u#{lib.pad(Number(chr.charCodeAt(0)).toString(16), 4, '0').toUpperCase()}" for chr in string) if lib.isString string

    return result.join ""

  ###
  # 将 UTF8 字符串转换为 BASE64
  # 
  # @private
  # @method  utf8_to_base64
  # @param   string {String}
  # @return  {String}
  ###   
  utf8_to_base64 = ( string ) ->
    result = string
    btoa = window.btoa
    atob = window.atob

    if @.isString string
      result = btoa(unescape(encodeURIComponent(string))) if @isFunction btoa

    return result

  storage.modules.Core.String =
    value: ""

    validator: ( object ) ->
      return @isString object

    handlers: [
      {
        ###
        # 用指定占位符填补字符串
        # 
        # @method  pad
        # @param   string {String}         源字符串
        # @param   length {Integer}        生成字符串的长度，正数为在后面补充，负数则在前面补充
        # @param   placeholder {String}    占位符
        # @return  {String}
        ###
        name: "pad"

        handler: ( string, length, placeholder ) ->
          # 占位符只能指定为一个字符
          # 占位符默认为空格
          placeholder = "\x20" if @isString(placeholder) is false or placeholder.length isnt 1

          # Set length to 0 if it isn't an integer.
          length = 0 if not @isInteger length

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

        validator: ( string ) ->
          return typeof string in ["string", "number"]
      },
      {
        ###
        # 将字符串首字母大写
        # 
        # @method  capitalize
        # @param   string {String}     源字符串
        # @param   isAll {Boolean}     是否将所有英文字符串首字母大写
        # @return  {String}
        ###
        name: "capitalize"

        handler: ( string, isAll ) ->
          exp = "[a-z]+"

          return string.replace (if isAll is true then new RegExp(exp, "ig") else new RegExp(exp)), ( c ) ->
              return c.charAt(0).toUpperCase() + c.slice(1).toLowerCase()
      },
      {
        ###
        # 将字符串转换为驼峰式
        # 
        # @method  camelCase
        # @param   string {String}         源字符串
        # @param   is_upper {Boolean}      是否为大驼峰式
        # @return  {String}
        ###
        name: "camelCase"

        handler: ( string, is_upper ) ->
          string = string.toLowerCase().replace /[-_\x20]([a-z]|[0-9])/ig, ( all, letter ) ->
              return letter.toUpperCase()

          firstLetter = string.charAt(0)

          string = (if is_upper is true then firstLetter.toUpperCase() else firstLetter.toLowerCase()) + string.slice(1)

          return string
      },
      {
        ###
        # 补零
        # 
        # @method  zerofill
        # @param   number {Number}     源数字
        # @param   digit {Integer}     数字位数，正数为在后面补充，负数则在前面补充
        # @return  {String}
        ###
        name: "zerofill"

        handler: ( number, digit ) ->
          result = ""
          lib = this
          rfloat = /^([-+]?\d+)\.(\d+)$/
          isFloat = rfloat.test number
          prefix = ""

          digit = parseInt digit

          # 浮点型数字时 digit 则为小数点后的位数
          if digit > 0 and isFloat
            number = (number + "").match rfloat
            prefix = "#{number[1] * 1}."
            number = number[2]
          # Negative number
          else if number * 1 < 0
            prefix = "-"
            number = (number + "").substring(1)

          result = lib.pad number, digit, "0"
          result = if digit < 0 and isFloat then "" else  prefix + result

          return result

        validator: ( number, digit ) ->
          return @isNumeric(number) and @isNumeric(digit) and /^-?[1-9]\d*$/.test(digit)
      },
      {
        ###
        # Removes whitespace from both ends of the string.
        #
        # @method  trim
        # @param   string {String}
        # @return  {String}
        # 
        # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/Trim
        ###
        name: "trim"

        handler: ( string ) ->
          # Make sure we trim BOM and NBSP (here's looking at you, Safari 5.0 and IE)
          rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g
          func = "".trim

          return if func and not func.call("\uFEFF\xA0") then func.call(string) else string.replace(rtrim, "")
      }
      # ,
      # {
      #   ###
      #   # Returns the characters in a string beginning at the specified location through the specified number of characters.
      #   #
      #   # @method  substr
      #   # @param   string {String}         The input string. Must be one character or longer.
      #   # @param   start {Integer}         Location at which to begin extracting characters.
      #   # @param   length {Integer}        The number of characters to extract.
      #   # @param   ignore {String/RegExp}  Characters to be ignored (will not include in the length).
      #   # @return  {String}
      #   # 
      #   # refer: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/substr
      #   ###
      #   name: "substr"

      #   handler: ( string, start, length, ignore ) ->
      #     args = arguments
      #     lib = this

      #     if args.length is 3 and lib.isNumeric(start) and start > 0 and (lib.isString(length) or lib.isRegExp(length))
      #       string = ignoreSubStr.apply lib, [string, start, length]
      #     else if lib.isNumeric(start) and start >= 0
      #       length = string.length if not lib.isNumeric(length) or length <= 0
      #       string = if lib.isString(ignore) or lib.isRegExp(ignore) then ignoreSubStr.apply(lib, [string.substring(start), length, ignore]) else string.substring(start, length)

      #     return string
      # }
      # ,
      # {
      #   ###
      #   # Return information about characters used in a string.
      #   #
      #   # Depending on mode will return one of the following:
      #   #  - 0: an array with the byte-value as key and the frequency of every byte as value
      #   #  - 1: same as 0 but only byte-values with a frequency greater than zero are listed
      #   #  - 2: same as 0 but only byte-values with a frequency equal to zero are listed
      #   #  - 3: a string containing all unique characters is returned
      #   #  - 4: a string containing all not used characters is returned
      #   # 
      #   # @method  countChars
      #   # @param   string {String}
      #   # @param   [mode] {Integer}
      #   # @return  {JSON}
      #   #
      #   # refer: http://www.php.net/manual/en/function.count-chars.php
      #   ###
      #   name: "countChars"

      #   handler: ( string, mode ) ->
      #     result = null;
      #     lib = this

      #     mode = 0 if not lib.isInteger(mode) or mode < 0

      #     bytes = {}
      #     chars = []

      #     lib.each string, ( chr, idx ) ->
      #       code = chr.charCodeAt(0)

      #       if lib.isNumber bytes[code]
      #         bytes[code]++
      #       else
      #         bytes[code] = 1
      #         chars.push(chr) if lib.inArray(chr, chars) < 0

      #     switch mode
      #       when 0
      #         break
      #       when 1
      #         result = bytes
      #       when 2
      #         break
      #       when 3
      #         result = chars.join ""
      #       when 4
      #         break

      #     return result

      #   value: null
      # }
    ]
      # /**
      #  * 将字符串转换为以 \u 开头的十六进制 Unicode
      #  * 
      #  * @method  unicode
      #  * @param   string {String}
      #  * @return  {String}
      #  */
      # // {
      # //     name: "unicode",
      # //     handler: function( string ) {
      # //         return unicode.call(this, string);
      # //     }
      # // }

      # /**
      #  * 对字符串编码
      #  * 
      #  * @method  encode
      #  * @param   target {String}     目标
      #  * @param   type {String}       编码类型
      #  * @return  {String}
      #  */
      # // {
      # //     name: "encode",
      # //     handler: function( target, type ) {
      # //         var result = target;

      # //         type = String(type).toLowerCase();

      # //         switch( type ) {
      # //             case "unicode":
      # //                 result = unicode.call(this, target);
      # //                 break;
      # //             case "base64":
      # //                 result = utf8_to_base64.call(this, target);
      # //                 break;
      # //         }

      # //         return result;
      # //     }
      # // },

      # /**
      #  * 对字符串解码
      #  * 
      #  * @method  decode
      #  * @param   target {String}     目标
      #  * @param   type {String}       目标类型
      #  * @return  {String}
      #  */
      # // {
      # //     name: "decode",
      # //     handler: function( target, type ) {}
      # // }
