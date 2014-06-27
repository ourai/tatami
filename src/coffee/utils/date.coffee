  # ====================
  # Date and time
  # ====================

  ###
  # 将日期字符串转化为日期对象
  #
  # @private
  # @method   dateStr2obj
  # @param    date_str {String}
  # @return   {Date}
  ###
  dateStr2obj = ( date_str ) ->
    date_str = @trim date_str
    date = new Date date_str

    if isNaN date.getTime()
      # 为了兼容 IE9-
      date_parts = date_str.match storage.regexps.date.iso8601
      date = if date_parts? then ISOstr2date.call(this, date_parts) else new Date

    return date

  ###
  # ISO 8601 日期字符串转化为日期对象
  #
  # @private
  # @method   ISOstr2date
  # @param    date_parts {Array}
  # @return   {Date}
  ###
  ISOstr2date = ( date_parts ) ->
    date_parts.shift()

    date = UTCstr2date.call this, date_parts
    tz_offset = timezoneOffset date_parts.slice(-1)[0]

    date.setTime(date.getTime() - tz_offset) unless tz_offset is 0

    return date

  ###
  # 转化为 UTC 日期对象
  #
  # @private
  # @method   UTCstr2date
  # @param    date_parts {Array}
  # @return   {Date}
  ###
  UTCstr2date = ( date_parts ) ->
    handlers = [
        "FullYear"
        "Month"
        "Date"
        "Hours"
        "Minutes"
        "Seconds"
        "Milliseconds"
      ]
    date = new Date

    @each date_parts, ( ele, i ) ->
      if ele? and ele isnt ""
        handler = handlers[i]

        date["setUTC#{handler}"](ele * 1 + if handler is "Month" then -1 else 0) if handler?

    return date

  ###
  # 相对于 UTC 的偏移值
  #
  # @private
  # @method   timezoneOffset
  # @param    timezone {String}
  # @return   {Integer}
  ###
  timezoneOffset = ( timezone ) ->
    offset = 0

    if /^(Z|[+-]\d{2}\:\d{2})$/.test timezone
      cap = timezone.charAt(0)

      if cap isnt "Z"
        offset = timezone.substring(1).split(":")
        offset = (cap + (offset[0] * 60 + offset[1] * 1)) * 60 * 1000

    return offset

  DateTimeNames = 
    month:
      long: [
          "January", "February", "March", "April",
          "May", "June", "July", "August",
          "September", "October", "November", "December"
        ]
      short: [
          "Jan", "Feb", "Mar", "Apr",
          "May", "Jun", "Jul", "Aug",
          "Sep", "Oct", "Nov", "Dec"
        ]
    week:
      long: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thurday", "Friday", "Saturday"]
      short: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  DateTimeFormats = 
    "d": ( date ) ->
      return dtwz.call this, date.getDate()
    "D": ( date ) ->
      return DateTimeNames.week.short[date.getDay()]
    "j": ( date ) ->
      return date.getDate()
    "l": ( date ) ->
      return DateTimeNames.week.long[date.getDay()]
    "N": ( date ) ->
      day = date.getDay()
      day = 7 if day is 0
      return day
    "S": ( date ) ->
      switch String(date.getDate()).slice -1
        when "1" then suffix = "st"
        when "2" then suffix = "nd"
        when "3" then suffix = "rd"
        else suffix = "th"
      return suffix
    "w": ( date ) ->
      return date.getDay()
    # "z": ( date ) ->
    # "W": ( date ) ->
    "F": ( date ) ->
      return DateTimeNames.month.long[date.getMonth()]
    "m": ( date ) ->
      return dtwz.call this, DateTimeFormats.n.call(this, date)
    "M": ( date ) ->
      return DateTimeNames.month.short[date.getMonth()]
    "n": ( date ) ->
      return date.getMonth() + 1
    # "t": ( date ) ->
    # "L": ( date ) ->
    # "o": ( date ) ->
    "Y": ( date ) ->
      return date.getFullYear()
    "y": ( date ) ->
      return String(date.getFullYear()).slice -2
    "a": ( date ) ->
      h = date.getHours()
      return if 0 < h < 12 then "am" else "pm"
    "A": ( date ) ->
      return DateTimeFormats.a.call(this, date).toUpperCase()
    # "B": ( date ) ->
    "g": ( date ) ->
      h = date.getHours()
      h = 24 if h is 0
      return if h > 12 then h - 12 else h
    "G": ( date ) ->
      return date.getHours()
    "h": ( date ) ->
      return dtwz.call this, DateTimeFormats.g.call(this, date)
    "H": ( date ) ->
      return dtwz.call this, DateTimeFormats.G.call(this, date)
    "i": ( date ) ->
      return dtwz.call this, date.getMinutes()
    "s": ( date ) ->
      return dtwz.call this, date.getSeconds()
    # "u": ( date ) ->

  ###
  # 添加前导“0”
  #
  # @private
  # @method   dtwz
  # @param    datetime {Integer}
  # @return   {String}
  ###
  dtwz = ( datetime ) ->
    return @pad datetime, -2, "0"

  ###
  # 格式化日期
  #
  # @private
  # @method   formatDate
  # @param    format {String}
  # @param    date {Date}
  # @return   {String}
  ###
  formatDate = ( format, date ) ->
    date = new Date if not @isDate(date) or isNaN(date.getTime())
    context = this
    formatted = format.replace new RegExp("([a-z]|\\\\)", "gi"), ( m, p..., o, s ) ->
      if m is "\\"
        return ""
      else
        handler = DateTimeFormats[m] if s.charAt(o - 1) isnt "\\"
      return if handler? then handler.call(context, date) else m

    return formatted

  storage.modules.Core.Date =
    handlers: [
      {
        ###
        # 格式化日期对象/字符串
        #
        # format 参照 PHP：
        #   http://www.php.net/manual/en/function.date.php
        # 
        # @method  date
        # @param   format {String}
        # @param   [date] {Date/String}
        # @return  {String}
        ###
        name: "date"

        handler: ( format, date ) ->
          if @isString date
            date = dateStr2obj.call this, date

          return formatDate.apply this, [format, date]

        value: ""

        validator: ( format ) ->
          return @isString format
      },
      {
        ###
        # 取得当前时间
        #
        # @method   now
        # @param    [is_object] {Boolean}
        # @return   {Integer/Date}
        ###
        name: "now"

        handler: ( is_object ) ->
          date = new Date

          return if is_object is true then date else date.getTime()
      }
    ]
